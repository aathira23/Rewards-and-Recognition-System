"""
Config service - Business logic for system configuration.
"""
from sqlalchemy.orm import Session
from typing import Optional

from app.repository.config_repository import ConfigRepository


class ConfigService:
    """Service for managing system-wide configuration."""

    def __init__(self, db: Session):
        self.db = db
        self.repository = ConfigRepository(db)

    def get_config(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Get a configuration value by key."""
        config = self.repository.get_by_key(key)
        return config.value if config else default

    def set_config(self, key: str, value: str, description: Optional[str] = None):
        """Set a configuration value."""
        return self.repository.upsert(key, value, description)

    def get_all_configs(self):
        """Get all configuration settings."""
        return self.repository.get_all()
