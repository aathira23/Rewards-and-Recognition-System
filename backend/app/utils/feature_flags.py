"""Feature flags helper — check whether optional features are enabled.

Reads boolean flags from `system_config` via `ConfigService`.

Supported keys:
- `feature.conversion_enabled` (default: 'true')

Usage:
    from app.utils.feature_flags import is_feature_enabled
    if not is_feature_enabled(db, 'conversion_enabled'):
        return client_error(message="Feature disabled", status_code=403)
"""
from sqlalchemy.orm import Session
from app.services.config_service import ConfigService

# Default values for all feature flags (all enabled by default)
_DEFAULTS = {
    'conversion_enabled': True,
}


def is_feature_enabled(db: Session, feature: str) -> bool:
    """Return True if the feature flag is enabled (or defaults to True if not set)."""
    service = ConfigService(db)
    key = f"feature.{feature}"
    val = service.get_config(key)
    if val is None:
        return _DEFAULTS.get(feature, True)
    return val.strip().lower() in ('true', '1', 'yes', 'on')


def get_all_feature_flags(db: Session) -> dict:
    """Return a dict of all feature flags with their current values."""
    result = {}
    for feature, default_val in _DEFAULTS.items():
        result[feature] = is_feature_enabled(db, feature)
    return result
