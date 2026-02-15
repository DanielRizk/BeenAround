"""
Central configuration.

We keep all environment variable reading here so:
- Your other files stay clean
- Adding new config is easy
- Testing is easier
"""

import os
from pydantic import BaseModel


class Settings(BaseModel):
    # Environment label (dev/stage/prod). Useful for toggles/logging.
    env: str = os.getenv("ENV", "dev")

    # Postgres connection parameters
    postgres_host: str = os.getenv("POSTGRES_HOST", "localhost")
    postgres_port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    postgres_db: str = os.getenv("POSTGRES_DB", "app")
    postgres_user: str = os.getenv("POSTGRES_USER", "app")
    postgres_password: str = os.getenv("POSTGRES_PASSWORD", "change_me")

    # JWT config
    jwt_secret: str = os.getenv("JWT_SECRET", "change_me")
    jwt_expires_min: int = int(os.getenv("JWT_EXPIRES_MIN", "10080"))

    # CORS configuration (comma-separated list)
    cors_origins: str = os.getenv("CORS_ORIGINS", "*")

    # File storage root directory
    storage_dir: str = os.getenv("STORAGE_DIR", "/data/storage")

    # Optional "seed admin" values (for quick bootstrap)
    admin_email: str = os.getenv("ADMIN_EMAIL", "")
    admin_password: str = os.getenv("ADMIN_PASSWORD", "")

    @property
    def database_url(self) -> str:
        """
        SQLAlchemy DB URL for psycopg v3.
        Example:
          postgresql+psycopg://user:pass@host:5432/dbname
        """
        return (
            f"postgresql+psycopg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


# A single settings instance used across the app
settings = Settings()
