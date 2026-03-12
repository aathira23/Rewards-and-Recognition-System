"""
Application configuration using Pydantic settings.
"""
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
    DEBUG: bool = True
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


settings = Settings()
