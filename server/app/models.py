"""
SQLAlchemy ORM models (tables).

No migrations:
    Base.metadata.create_all(bind=engine) on startup.
"""

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import declarative_base
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime, timezone, timedelta
import uuid


Base = declarative_base()


def utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)

    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)

    profile_pic_path = Column(String, nullable=True)

    password_hash = Column(String, nullable=False)

    # Entire app data blob (countries, cities, visited, memos, settings...)
    app_data = Column(JSONB, nullable=False, default=dict)

    # Mirrors app settings for quick checks in feed queries
    travel_visible_to_friends = Column(Boolean, nullable=False, default=True)

    is_admin = Column(Boolean, default=False, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)

    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False)


class Friend(Base):
    __tablename__ = "friends"
    __table_args__ = (UniqueConstraint("user_id", "friend_id", name="uq_friend_pair"),)

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    friend_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class Activity(Base):
    __tablename__ = "activities"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    actor_user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)

    type = Column(String, index=True, nullable=False)      # e.g. "travel_updated"
    payload = Column(JSONB, nullable=False, default=dict)  # details for feed

    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at = Column(DateTime(timezone=True), index=True, nullable=False, default=lambda: utcnow() + timedelta(days=7))


class ActivityReaction(Base):
    __tablename__ = "activity_reactions"
    __table_args__ = (UniqueConstraint("activity_id", "user_id", name="uq_react_once"),)

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    activity_id = Column(String, ForeignKey("activities.id"), index=True, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)

    reaction = Column(String, nullable=False)  # "like", "love", ...
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)


class RevokedToken(Base):
    """
    Supports real logout for JWT by revoking token IDs (jti).
    """
    __tablename__ = "revoked_tokens"

    jti = Column(String, primary_key=True)  # token id
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), index=True, nullable=False)
