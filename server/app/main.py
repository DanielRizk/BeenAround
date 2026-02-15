"""
FastAPI entry point.
"""

from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .settings import settings
from .db import engine, SessionLocal
from .models import Base, User
from .storage import ensure_storage_dir
from .auth import hash_password
from .monitoring import monitoring_middleware
from .admin import setup_admin

# Routers
from .api.routes.health import router as health_router
from .api.routes.auth import router as auth_router
from .api.routes.users import router as users_router
from .api.routes.files import router as files_router
from .api.routes.data import router as data_router
from .api.routes.friends import router as friends_router
from .api.routes.feed import router as feed_router
from .api.routes.monitor import router as monitor_router

from fastapi.responses import RedirectResponse
from starlette.middleware.sessions import SessionMiddleware


app = FastAPI(title="Server API", version="1.0.0")

class ProtectInternalPagesMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        path = request.url.path

        # Always allow login/logout
        if path.startswith("/internal/login") or path.startswith("/internal/logout"):
            return await call_next(request)

        # Let preflight through
        if request.method == "OPTIONS":
            return await call_next(request)

        # Protect internal areas
        if path.startswith("/db") or path.startswith("/admin") or path.startswith("/monitor"):
            # ✅ now safe: SessionMiddleware will already have populated this
            if not request.session.get("admin_logged_in"):
                next_url = path + (("?" + request.url.query) if request.url.query else "")
                return RedirectResponse(url=f"/internal/login?next={next_url}", status_code=303)

        return await call_next(request)


app.add_middleware(ProtectInternalPagesMiddleware)

app.add_middleware(
    SessionMiddleware,
    secret_key=settings.jwt_secret,
    same_site="lax",
    #https_only=(settings.env == "prod"),
    https_only=False,
)

def seed_admin_if_configured() -> None:
    if not settings.admin_email or not settings.admin_password:
        return

    db: Session = SessionLocal()
    try:
        # 1) Fast path: already exists -> ensure admin -> return
        existing = (
            db.query(User)
            .filter(User.email == settings.admin_email, User.is_deleted == False)  # noqa: E712
            .first()
        )
        if existing:
            # Optional hardening: ensure the existing user is actually admin
            if not existing.is_admin:
                existing.is_admin = True
                db.commit()
            return

        # 2) Create admin (fill ALL NOT NULL fields if your model doesn't default them)
        admin = User(
            email=settings.admin_email,
            username="admin",
            first_name="Admin",
            last_name="User",
            password_hash=hash_password(settings.admin_password),
            is_admin=True,

            # IMPORTANT: set these if your model doesn't provide defaults
            app_data={},
            travel_visible_to_friends=False,
            is_deleted=False,
        )

        db.add(admin)

        # 3) Commit safely under concurrency (Gunicorn workers)
        try:
            db.commit()
        except IntegrityError:
            # Another worker probably inserted it first. Rollback and continue.
            db.rollback()
            return

    finally:
        db.close()


@app.on_event("startup")
def on_startup():
    ensure_storage_dir()

    # Ensure schema init runs once even if multiple workers boot.
    with engine.begin() as conn:
        conn.execute(text("SELECT pg_advisory_lock(123456789);"))
        try:
            Base.metadata.create_all(bind=conn)
        finally:
            conn.execute(text("SELECT pg_advisory_unlock(123456789);"))

    seed_admin_if_configured()


# CORS
origins = [o.strip() for o in settings.cors_origins.split(",")] if settings.cors_origins else ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Monitoring middleware
app.middleware("http")(monitoring_middleware)

# Admin DB UI at /db
setup_admin(app, engine)

# Routers
app.include_router(health_router, tags=["health"])
app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(users_router, prefix="/users", tags=["users"])
app.include_router(files_router, prefix="/files", tags=["files"])
app.include_router(data_router, prefix="/data", tags=["data"])
app.include_router(friends_router, prefix="/friends", tags=["friends"])
app.include_router(feed_router, prefix="/feed", tags=["feed"])
app.include_router(monitor_router, tags=["monitor"])

# /doc -> /docs
@app.get("/doc", include_in_schema=False)
def doc_redirect():
    return RedirectResponse(url="/docs")

@app.get("/db", include_in_schema=False)
def db_redirect():
    return RedirectResponse(url="/admin", status_code=307)

@app.get("/db/{path:path}", include_in_schema=False)
def db_redirect_path(path: str):
    return RedirectResponse(url=f"/admin/{path}", status_code=307)

