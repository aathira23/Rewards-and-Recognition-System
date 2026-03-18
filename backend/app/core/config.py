"""
Application configuration using Pydantic settings.
"""
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    APP_NAME: str = "Rewards & Recognition System"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"

    # Database
    DATABASE_URL: str

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours

    # CORS Configuration
    ALLOWED_ORIGINS: str = "*"  # Use comma-separated URLs in production: "http://localhost:3000,https://yourdomain.com"

    # Points expiry reminder window (days before expiry to notify users)
    POINTS_EXPIRY_REMINDER_DAYS: int = 7

    # SMTP / Email Configuration
    SMTP_HOST: str = "localhost"
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_USE_TLS: bool = True
    SMTP_FROM_EMAIL: str = "noreply@example.com"
    SMTP_FROM_NAME: str = "Rewards & Recognition"

    # Front-end base URL (used for links in emails)
    FRONTEND_URL: str = "http://localhost:8080"

    ECARD_CONSECUTIVE_WINDOW_HOURS: int = 24
    ECARD_DEFAULT_COOLDOWN_HOURS: int = 1

    # ── User Service Integration ──────────────────────────────
    USER_SERVICE_BASE_URL: str = "http://localhost:9102"
    # Cache 1 endpoint — validate token and get user identity
    GET_USER_DETAILS_URL: str = "http://localhost:9102/python/api/v1/auth/token/get_user_details"
    # Cache 2 endpoints — fetch user profiles by id or in bulk
    GET_USERS_URL: str = "http://localhost:9102/python/api/v1/users"
    GET_USER_BATCH_URL: str = "http://localhost:9102/python/api/v1/users/batch"
    # Set False in production only if User Service uses a self-signed cert
    USER_SERVICE_VERIFY_SSL: bool = True

    # Auth mode: "user_service" (production) or "local" (dev/testing with local JWT)
    AUTH_MODE: str = "local"

    # Optional service/system token used by background jobs (celebrations, pending-approvals)
    # to call the User Service without a per-request Bearer token.
    # Set this to a long-lived service account token in production.
    SYSTEM_TOKEN: Optional[str] = None


settings = Settings()
