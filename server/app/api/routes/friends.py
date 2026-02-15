from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ...auth import get_current_user
from ...db import get_db
from ...models import User, Friend

router = APIRouter()


@router.get("")
def list_friends(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rows = db.query(Friend).filter(Friend.user_id == user.id).all()
    friend_ids = [r.friend_id for r in rows]
    friends = db.query(User).filter(User.id.in_(friend_ids), User.is_deleted == False).all()  # noqa: E712
    return [{
        "id": f.id,
        "username": f.username,
        "first_name": f.first_name,
        "last_name": f.last_name,
        "profile_pic_path": f.profile_pic_path,
    } for f in friends]


@router.post("/{username}")
def add_friend(username: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    other = db.query(User).filter(User.username == username, User.is_deleted == False).first()  # noqa: E712
    if not other:
        raise HTTPException(status_code=404, detail="User not found")
    if other.id == user.id:
        raise HTTPException(status_code=400, detail="Cannot friend yourself")

    # store both directions
    for a, b in [(user.id, other.id), (other.id, user.id)]:
        exists = db.query(Friend).filter(Friend.user_id == a, Friend.friend_id == b).first()
        if not exists:
            db.add(Friend(user_id=a, friend_id=b))

    db.commit()
    return {"status": "ok"}


@router.delete("/{username}")
def remove_friend(username: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    other = db.query(User).filter(User.username == username, User.is_deleted == False).first()  # noqa: E712
    if not other:
        raise HTTPException(status_code=404, detail="User not found")

    db.query(Friend).filter(Friend.user_id == user.id, Friend.friend_id == other.id).delete()
    db.query(Friend).filter(Friend.user_id == other.id, Friend.friend_id == user.id).delete()
    db.commit()
    return {"status": "ok"}
