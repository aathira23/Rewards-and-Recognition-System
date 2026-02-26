"""
Config service - Business logic for system configuration.
"""
from sqlalchemy.orm import Session
from app.models.system_config import SystemConfig
from typing import Optional


class ConfigService:
    """Service for managing system-wide configuration."""

    def __init__(self, db: Session):
        self.db = db

    def get_config(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Get a configuration value by key."""
        config = self.db.query(SystemConfig).filter(SystemConfig.key == key).first()
        if config:
            return config.value
        return default

    def set_config(self, key: str, value: str, description: Optional[str] = None):
        """Set a configuration value."""
        config = self.db.query(SystemConfig).filter(SystemConfig.key == key).first()
        if config:
            config.value = value
            if description:
                config.description = description
        else:
            config = SystemConfig(key=key, value=value, description=description)
            self.db.add(config)
        
        self.db.commit()
        return config

    def get_all_configs(self):
        """Get all configuration settings."""
        return self.db.query(SystemConfig).all()
