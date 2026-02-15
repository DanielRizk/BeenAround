from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ...auth import get_current_user
from ...db import get_db
from ...models import User, Activity
from ...schemas import AppDataOut, AppDataUpdate

router = APIRouter()


def _merge_dict(dst: dict, src: dict) -> dict:
    # simple recursive merge
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            dst[k] = _merge_dict(dst[k], v)
        else:
            dst[k] = v
    return dst


@router.get("", response_model=AppDataOut)
def get_data(user: User = Depends(get_current_user)):
    return AppDataOut(app_data=user.app_data or {})


@router.put("", response_model=AppDataOut)
def update_data(payload: AppDataUpdate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    current = user.app_data or {}
    updated = _merge_dict(current, payload.app_data or {})
    user.app_data = updated

    # Mirror visibility flag from app settings if present:
    # expecting something like app_data["settings"]["travelVisibleToFriends"] = bool
    settings = (updated or {}).get("settings") or {}
    if "travelVisibleToFriends" in settings:
        user.travel_visible_to_friends = bool(settings["travelVisibleToFriends"])

    # Add activity (for friends feed)
    db.add(Activity(
        actor_user_id=user.id,
        type="data_updated",
        payload={"changed_keys": list((payload.app_data or {}).keys())},
    ))

    db.add(user)
    db.commit()
    db.refresh(user)
    return AppDataOut(app_data=user.app_data or {})


@router.delete("")
def delete_data(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    user.app_data = {}
    db.add(user)
    db.commit()
    return {"status": "ok"}
