"""
Database setup: engine + sessions.

Key ideas:
- engine: manages a connection pool to DB
- SessionLocal: factory to create per-request sessions
- get_db: FastAPI dependency that yields a session and closes it after request
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from .settings import settings

# Create SQLAlchemy engine (connection pool)
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,  # checks connection health before using it
    pool_size=5,         # base pool size (tune later)
    max_overflow=10,     # extra connections if needed
)

# Create sessions bound to this engine
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    """
    FastAPI dependency:
    - opens a DB session
    - yields it to your endpoint
    - closes it after the endpoint finishes (even on errors)
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
