from sqlalchemy import (
    Column, String, DateTime, Boolean, Integer, BigInteger, ForeignKey, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid
from .db import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(64), unique=True, nullable=False, index=True)
    first_name = Column(String(80), nullable=False)
    last_name = Column(String(80), nullable=False)
    password_hash = Column(String(255), nullable=False)

    is_deleted = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # stored file path (inside container) or None
    profile_pic_path = Column(String(512), nullable=True)

class UserSnapshot(Base):
    """
    Single “latest snapshot” per user.
    rev increments every time snapshot is updated.
    """
    __tablename__ = "user_snapshots"
    __table_args__ = (UniqueConstraint("user_id", name="uq_user_snapshots_user_id"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    schema_version = Column(Integer, nullable=False, default=1)
    rev = Column(BigInteger, nullable=False, default=0)

    snapshot = Column(JSONB, nullable=False, default=dict)

    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    # optional client metadata
    last_device_id = Column(String(128), nullable=True)
    last_client_ts_ms = Column(BigInteger, nullable=True)

# ---- Future-ready tables (placeholders for friends/feed) ----
class Friendship(Base):
    __tablename__ = "friendships"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    friend_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

class FeedEvent(Base):
    __tablename__ = "feed_events"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    payload = Column(JSONB, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
