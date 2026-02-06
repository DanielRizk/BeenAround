import os
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from uuid import UUID

from .db import get_db, engine
from .models import Base, User, UserSnapshot
from .schemas import (
    RegisterRequest, LoginRequest, TokenResponse,
    MeResponse, UpdateMeRequest,
    SnapshotResponse, SnapshotUpdateRequest, ConflictResponse
)
from .auth import hash_password, verify_password, create_access_token, get_current_user
from .storage import ensure_dirs, user_pic_path

app = FastAPI(title="BeenAround Backend", version="0.1.0")

# For dev: allow everything. For prod: restrict to your app origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    ensure_dirs()
    Base.metadata.create_all(bind=engine)

# -------------------------
# Auth
# -------------------------
@app.post("/auth/register", response_model=TokenResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    exists = db.query(User).filter(User.username == payload.username).first()
    if exists:
        raise HTTPException(status_code=409, detail="Username already exists")

    user = User(
        username=payload.username,
        first_name=payload.first_name,
        last_name=payload.last_name,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.flush()  # get user.id

    # Create snapshot row
    snap = UserSnapshot(
        user_id=user.id,
        schema_version=payload.schema_version,
        rev=0,
        snapshot=payload.initial_snapshot or {"schemaVersion": payload.schema_version},
    )
    db.add(snap)
    db.commit()

    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)

@app.post("/auth/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == payload.username, User.is_deleted == False).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)

# -------------------------
# Account
# -------------------------
@app.get("/users/me", response_model=MeResponse)
def me(user: User = Depends(get_current_user)):
    return MeResponse(
        id=user.id,
        username=user.username,
        first_name=user.first_name,
        last_name=user.last_name,
        has_profile_pic=bool(user.profile_pic_path),
    )

@app.patch("/users/me", response_model=MeResponse)
def update_me(payload: UpdateMeRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if payload.first_name is not None:
        user.first_name = payload.first_name
    if payload.last_name is not None:
        user.last_name = payload.last_name

    db.add(user)
    db.commit()
    db.refresh(user)

    return MeResponse(
        id=user.id,
        username=user.username,
        first_name=user.first_name,
        last_name=user.last_name,
        has_profile_pic=bool(user.profile_pic_path),
    )

@app.delete("/users/me")
def delete_me(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    user.is_deleted = True
    db.add(user)
    db.commit()
    return {"ok": True}

# -------------------------
# Profile picture
# -------------------------
@app.put("/users/me/profile-pic")
def upload_profile_pic(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    file: UploadFile = File(...)
):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    # decide extension
    ext = "jpg"
    if file.filename and "." in file.filename:
        ext = file.filename.rsplit(".", 1)[-1]

    path = user_pic_path(user.id, ext)
    content = file.file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 5MB)")

    path.write_bytes(content)
    user.profile_pic_path = str(path)
    db.add(user)
    db.commit()

    return {"ok": True}

@app.get("/users/me/profile-pic")
def download_profile_pic(user: User = Depends(get_current_user)):
    if not user.profile_pic_path:
        raise HTTPException(status_code=404, detail="No profile picture")

    p = user.profile_pic_path
    try:
        with open(p, "rb") as f:
            data = f.read()
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="No profile picture")

    # fastapi will infer response, but we set a safe type
    return app.response_class(content=data, media_type="image/jpeg")

@app.delete("/users/me/profile-pic")
def delete_profile_pic(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if not user.profile_pic_path:
        # idempotent delete
        return {"ok": True}

    try:
        os.remove(user.profile_pic_path)
    except FileNotFoundError:
        pass

    user.profile_pic_path = None
    db.add(user)
    db.commit()
    return {"ok": True}

# -------------------------
# Sync (snapshot)
# -------------------------
@app.get("/sync/snapshot", response_model=SnapshotResponse)
def get_snapshot(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    row = db.query(UserSnapshot).filter(UserSnapshot.user_id == user.id).first()
    if not row:
        row = UserSnapshot(user_id=user.id, schema_version=1, rev=0, snapshot={"schemaVersion": 1})
        db.add(row)
        db.commit()
        db.refresh(row)
    return SnapshotResponse(schema_version=row.schema_version, rev=int(row.rev), snapshot=row.snapshot)

@app.put(
    "/sync/snapshot",
    responses={409: {"model": ConflictResponse}},
    response_model=SnapshotResponse
)
def put_snapshot(
    payload: SnapshotUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    row = db.query(UserSnapshot).filter(UserSnapshot.user_id == user.id).with_for_update().first()
    if not row:
        row = UserSnapshot(user_id=user.id, schema_version=payload.schema_version, rev=0, snapshot={})
        db.add(row)
        db.flush()

    current_rev = int(row.rev)

    # optimistic concurrency
    if payload.base_rev != current_rev:
        current = SnapshotResponse(schema_version=row.schema_version, rev=current_rev, snapshot=row.snapshot)
        raise HTTPException(
            status_code=409,
            detail={
                "message": "Conflict: snapshot changed on server",
                "current": current.model_dump(),
            },
        )

    row.schema_version = payload.schema_version
    row.snapshot = payload.snapshot
    row.rev = current_rev + 1
    row.last_device_id = payload.device_id
    row.last_client_ts_ms = payload.client_ts_ms

    db.add(row)
    db.commit()
    db.refresh(row)

    return SnapshotResponse(schema_version=row.schema_version, rev=int(row.rev), snapshot=row.snapshot)

@app.get("/health")
def health():
    return {"ok": True}
