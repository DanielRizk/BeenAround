from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from pathlib import Path

from ...auth import get_current_user
from ...models import User
from ...schemas import FileMeta
from ...storage import save_upload

router = APIRouter()

@router.post("/upload", response_model=FileMeta)
async def upload_file(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    target_path: Path = await save_upload(file, subdir=user.id)
    size = target_path.stat().st_size
    return FileMeta(
        filename=file.filename,
        path=str(target_path),
        size=size,
        content_type=file.content_type,
    )


@router.put("/profile-pic", response_model=FileMeta)
async def update_profile_pic(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    # store under user folder, fixed filename
    target_path: Path = await save_upload(file, subdir=user.id, force_name="profile_pic")
    user.profile_pic_path = str(target_path)
    size = target_path.stat().st_size
    return FileMeta(filename=file.filename, path=str(target_path), size=size, content_type=file.content_type)


@router.delete("/profile-pic")
def delete_profile_pic(user: User = Depends(get_current_user)):
    if not user.profile_pic_path:
        raise HTTPException(status_code=404, detail="No profile pic")
    user.profile_pic_path = None
    return {"status": "ok"}
