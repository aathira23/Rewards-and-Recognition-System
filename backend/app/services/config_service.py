"""
Config service - Business logic for system configuration.

Uses a module-level TTLCache so config values (which rarely change) are not
fetched from the DB on every single request.  The cache is automatically
invalidated on writes (set_config) and expires after 1 hour.
"""
import logging
from sqlalchemy.orm import Session
from typing import Optional
from cachetools import TTLCache

from app.repository.config_repository import ConfigRepository

logger = logging.getLogger(__name__)

# Module-level cache: key → value string.  1 h TTL, 500 entries max.
_config_cache: TTLCache = TTLCache(maxsize=500, ttl=60 * 60)


class ConfigService:
    """Service for managing system-wide configuration."""

    def __init__(self, db: Session):
        self.db = db
        self.repository = ConfigRepository(db)

    def get_config(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Get a configuration value by key (served from cache when possible)."""
        if key in _config_cache:
            return _config_cache[key]
        config = self.repository.get_by_key(key)
        value = config.value if config else default
        _config_cache[key] = value
        return value

    def set_config(self, key: str, value: str, description: Optional[str] = None):
        """Set a configuration value and invalidate its cache entry."""
        result = self.repository.upsert(key, value, description)
        _config_cache.pop(key, None)
        logger.info("Config cache invalidated for key=%r", key)
        return result

    def get_all_configs(self):
        """Get all configuration settings."""
        return self.repository.get_all()
