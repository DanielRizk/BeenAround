from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Any, Dict, List


# -------------------------
# Auth
# -------------------------

class UserRegister(BaseModel):
    first_name: str = Field(min_length=1, max_length=64)
    last_name: str = Field(min_length=1, max_length=64)
    username: str = Field(min_length=3, max_length=32)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class UserLogin(BaseModel):
    # allow login by email OR username
    identifier: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# -------------------------
# Users
# -------------------------

class UserOut(BaseModel):
    id: str
    first_name: str
    last_name: str
    username: str
    email: EmailStr
    profile_pic_path: Optional[str] = None
    travel_visible_to_friends: bool
    is_admin: bool


class UserPublic(BaseModel):
    id: str
    first_name: str
    last_name: str
    username: str
    profile_pic_path: Optional[str] = None
    travel_visible_to_friends: bool


# -------------------------
# App Data
# -------------------------

class AppDataOut(BaseModel):
    app_data: Dict[str, Any]


class AppDataUpdate(BaseModel):
    # patch/merge update (safer). If you want "replace", just set replace=True in endpoint.
    app_data: Dict[str, Any]


# -------------------------
# Feed
# -------------------------

class ActivityOut(BaseModel):
    id: str
    actor_user_id: str
    type: str
    payload: Dict[str, Any]
    created_at: str
    expires_at: str


class ReactRequest(BaseModel):
    reaction: str = Field(min_length=1, max_length=16)


# -------------------------
# Files
# -------------------------

class FileMeta(BaseModel):
    filename: str
    path: str
    size: int
    content_type: Optional[str] = None
