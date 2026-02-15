from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from ...auth import get_current_user
from ...db import get_db
from ...models import User, Friend, Activity, ActivityReaction
from ...schemas import ReactRequest

router = APIRouter()


def cleanup_expired(db: Session):
    now = datetime.now(timezone.utc)
    db.query(ActivityReaction).filter(
        ActivityReaction.activity_id.in_(
            db.query(Activity.id).filter(Activity.expires_at < now)
        )
    ).delete(synchronize_session=False)
    db.query(Activity).filter(Activity.expires_at < now).delete(synchronize_session=False)
    db.commit()


@router.get("")
def get_feed(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    cleanup_expired(db)

    friend_ids = [r.friend_id for r in db.query(Friend).filter(Friend.user_id == user.id).all()]
    if not friend_ids:
        return []

    now = datetime.now(timezone.utc)
    # Note: visibility logic: if actor hides travel, you may still show non-travel activities.
    # For now we show all activities, but you can filter by activity type if needed.
    q = (
        db.query(Activity)
        .filter(Activity.actor_user_id.in_(friend_ids), Activity.expires_at >= now)
        .order_by(Activity.created_at.desc())
        .limit(200)
    )
    activities = q.all()

    # reactions counts
    act_ids = [a.id for a in activities]
    reactions = db.query(ActivityReaction).filter(ActivityReaction.activity_id.in_(act_ids)).all()

    react_map = {}
    for r in reactions:
        react_map.setdefault(r.activity_id, {})
        react_map[r.activity_id].setdefault(r.reaction, 0)
        react_map[r.activity_id][r.reaction] += 1

    return [{
        "id": a.id,
        "actor_user_id": a.actor_user_id,
        "type": a.type,
        "payload": a.payload,
        "created_at": a.created_at.isoformat(),
        "expires_at": a.expires_at.isoformat(),
        "reactions": react_map.get(a.id, {}),
    } for a in activities]


@router.post("/activities/{activity_id}/react")
def react(activity_id: str, payload: ReactRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    a = db.query(Activity).filter(Activity.id == activity_id).first()
    if not a:
        raise HTTPException(status_code=404, detail="Activity not found")

    existing = db.query(ActivityReaction).filter(
        ActivityReaction.activity_id == activity_id,
        ActivityReaction.user_id == user.id,
    ).first()

    if existing:
        existing.reaction = payload.reaction
        db.add(existing)
    else:
        db.add(ActivityReaction(activity_id=activity_id, user_id=user.id, reaction=payload.reaction))

    db.commit()
    return {"status": "ok"}
