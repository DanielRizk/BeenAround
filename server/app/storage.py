"""
File storage helpers.

We keep file handling in its own module so you can later replace it with:
- S3 storage
- Azure Blob storage
- GCS
without touching endpoints much.
"""

from pathlib import Path
from fastapi import UploadFile
import aiofiles

from .settings import settings


def ensure_storage_dir() -> Path:
    """
    Ensure the storage directory exists (create if missing).
    Called on app startup.
    """
    root = Path(settings.storage_dir)
    root.mkdir(parents=True, exist_ok=True)
    return root


async def save_upload(file: UploadFile, subdir: str = "") -> Path:
    """
    Save an uploaded file to disk.

    This simple version reads file into memory then writes it.
    For large files, you would stream chunks.
    """
    root = ensure_storage_dir()
    target_dir = root / subdir
    target_dir.mkdir(parents=True, exist_ok=True)

    # WARNING: in real production, sanitize filenames or generate unique names
    target_path = target_dir / file.filename

    async with aiofiles.open(target_path, "wb") as out:
        content = await file.read()
        await out.write(content)

    return target_path
