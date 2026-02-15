from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ...auth import get_current_user
from ...db import get_db
from ...models import User
from ...schemas import UserOut, UserPublic

router = APIRouter()


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
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


@router.get("/{username}", response_model=UserPublic)
def get_user(username: str, db: Session = Depends(get_db), current: User = Depends(get_current_user)):
    u = db.query(User).filter(User.username == username, User.is_deleted == False).first()  # noqa: E712
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    return UserPublic(
        id=u.id,
        first_name=u.first_name,
        last_name=u.last_name,
        username=u.username,
        profile_pic_path=u.profile_pic_path,
        travel_visible_to_friends=u.travel_visible_to_friends,
    )
