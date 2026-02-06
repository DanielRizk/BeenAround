from pydantic import BaseModel, Field
from typing import Any, Optional, Dict
from uuid import UUID

class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)
    password: str = Field(min_length=8, max_length=128)

    # optional: migrate guest data at signup
    initial_snapshot: Optional[Dict[str, Any]] = None
    schema_version: int = 1

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class MeResponse(BaseModel):
    id: UUID
    username: str
    first_name: str
    last_name: str
    has_profile_pic: bool

class UpdateMeRequest(BaseModel):
    first_name: Optional[str] = Field(default=None, min_length=1, max_length=80)
    last_name: Optional[str] = Field(default=None, min_length=1, max_length=80)

class SnapshotResponse(BaseModel):
    schema_version: int
    rev: int
    snapshot: Dict[str, Any]

class SnapshotUpdateRequest(BaseModel):
    schema_version: int = 1
    base_rev: int = 0
    snapshot: Dict[str, Any]
    device_id: Optional[str] = None
    client_ts_ms: Optional[int] = None

class ConflictResponse(BaseModel):
    message: str
    current: SnapshotResponse
