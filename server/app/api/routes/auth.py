from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from ...db import get_db
from ...models import User, RevokedToken
from ...schemas import UserRegister, UserLogin, TokenResponse, UserOut
from ...auth import hash_password, verify_password, create_access_token, decode_token, get_current_user

router = APIRouter()


@router.post("/register", response_model=UserOut)
def register(payload: UserRegister, db: Session = Depends(get_db)):
    # Unique checks
    if db.query(User).filter(User.email == payload.email, User.is_deleted == False).first():  # noqa: E712
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    if db.query(User).filter(User.username == payload.username, User.is_deleted == False).first():  # noqa: E712
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already taken")

    user = User(
        first_name=payload.first_name,
        last_name=payload.last_name,
        username=payload.username,
        email=payload.email,
        password_hash=hash_password(payload.password),
        app_data={},  # start empty; client can PUT /data
        travel_visible_to_friends=True,
        is_admin=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return UserOut(
        id=user.id,
        first_name=user.first_name,
        last_name=user.last_name,
        username=user.username,
        email=user.email,
        profile_pic_path=user.profile_pic_path,
        travel_visible_to_friends=user.travel_visible_to_friends,
        is_admin=user.is_admin,
    )


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    # identifier can be email or username
    user = (
        db.query(User)
        .filter(
            (User.email == payload.identifier) | (User.username == payload.identifier),
            User.is_deleted == False,  # noqa: E712
        )
        .first()
    )

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    return TokenResponse(access_token=create_access_token(user.id))


@router.post("/logout")
def logout(
    request: Request,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # read bearer token
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        raise HTTPException(status_code=400, detail="Missing bearer token")

    token = auth.split(" ", 1)[1].strip()
    payload = decode_token(token)
    jti = payload.get("jti")
    exp = payload.get("exp")

    if not jti or not exp:
        raise HTTPException(status_code=400, detail="Invalid token")

    expires_at = datetime.fromtimestamp(int(exp), tz=timezone.utc)
    db.add(RevokedToken(jti=jti, user_id=user.id, expires_at=expires_at))
    db.commit()

    return {"status": "ok"}
