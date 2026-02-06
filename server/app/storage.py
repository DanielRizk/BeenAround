import os
from pathlib import Path
from uuid import UUID

DATA_DIR = Path(os.getenv("DATA_DIR", "/data"))
UPLOADS_DIR = DATA_DIR / "uploads"

def ensure_dirs():
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

def user_pic_path(user_id: UUID, ext: str) -> Path:
    # store per-user file, overwrite on update
    safe_ext = ext.lower().strip(".")
    if safe_ext not in {"jpg", "jpeg", "png", "webp"}:
        safe_ext = "jpg"
    return UPLOADS_DIR / f"{user_id}.{safe_ext}"
