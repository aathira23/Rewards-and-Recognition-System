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

    # ── Database — generic multi-DB config (matches Styria service pattern) ──
    # Set DB_TYPE to one of: "mysql" | "postgresql" | "mssql"
    DB_TYPE: str = "postgresql"

    # MySQL / MariaDB
    MYSQL_DB_SERVER: str = ""
    MYSQL_DB_PORT: int = 3306
    MYSQL_DB_USER: str = ""
    MYSQL_DB_PASSWORD: str = ""
    MYSQL_DB_NAME: str = ""

    # MSSQL (SQL Server)
    MSSQL_DB_SERVER: str = ""
    MSSQL_DB_PORT: int = 1433
    MSSQL_DB_USER: str = ""
    MSSQL_DB_PASSWORD: str = ""
    MSSQL_DB_NAME: str = ""

    # PostgreSQL (legacy / dev)
    POSTGRES_DB_SERVER: str = ""
    POSTGRES_DB_PORT: int = 5432
    POSTGRES_DB_USER: str = ""
    POSTGRES_DB_PASSWORD: str = ""
    POSTGRES_DB_NAME: str = ""
    POSTGRES_DB_SCHEMA: str = ""

    # Direct URL override — used when DB_TYPE="postgresql" and a full URL is provided.
    # Set this OR the POSTGRES_DB_* fields above, not both.
    DATABASE_URL: Optional[str] = None

    # CORS Configuration
    ALLOWED_ORIGINS: str = "*"  # Use comma-separated URLs in production: "http://localhost:3000,https://yourdomain.com"

    # Points expiry reminder window (days before expiry to notify users)
    POINTS_EXPIRY_REMINDER_DAYS: int = 7

    # Email sender configuration (used by the notification service)
    SUPPORT_EMAIL: str = "noreply@example.com"
    SENDER_NAME: str = "Rewards & Recognition"

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
    # Login proxy endpoint — used in user_service mode to forward credentials to Styria
    STYRIA_LOGIN_URL: str = "http://localhost:9102/python/api/v1/auth/login"
    # Set False in production only if User Service uses a self-signed cert
    USER_SERVICE_VERIFY_SSL: bool = True

    # Optional service/system token used by background jobs (celebrations, pending-approvals)
    # to call the User Service without a per-request Bearer token.
    # Set this to a long-lived service account token in production.
    SYSTEM_TOKEN: Optional[str] = None

    # ── Notification Service Integration ──────────────────────────────────
    # Base URL of the Styria notification microservice (Java/Spring Boot).
    # Staging: https://api-styria-staging.tarento.dev  (same gateway as User Service)
    # Local dev: http://localhost:9030
    NOTIFICATION_SERVICE_BASE_URL: str = "http://localhost:9030"
    # Set True to also send Microsoft Teams messages for key R&R events
    # (award approvals, recognitions, celebrations). Requires the notification
    # service to be configured with valid MS Graph API credentials.
    TEAMS_NOTIFICATIONS_ENABLED: bool = True
    # Comma-separated list of Teams recipient email addresses for broadcast events.
    TEAMS_RECIPIENTS: str = ""
    # MS Teams team ID used by the notification service for channel messages.
    TEAMS_TEAM_ID: str = ""
    # Set False when notification service uses a self-signed certificate (staging).
    NOTIFICATION_SERVICE_VERIFY_SSL: bool = False


settings = Settings()
