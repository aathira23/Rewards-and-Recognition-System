"""
Application constants.
"""

# Points and rewards
DEFAULT_POINTS_EXPIRY_DAYS = 365
MIN_CONVERSION_POINTS = 100

# Pagination
DEFAULT_PAGE_SIZE = 6
MAX_PAGE_SIZE = 100

# Notifications
NOTIFICATION_RETENTION_DAYS = 90

# Celebrations
CELEBRATION_RETRY_MAX_ATTEMPTS = 3


def clamp_pagination(page: int = 1, per_page: int = DEFAULT_PAGE_SIZE) -> tuple:
    """Validate and clamp pagination parameters. Returns (page, per_page, skip)."""
    page = max(1, page)
    per_page = max(1, min(per_page, MAX_PAGE_SIZE))
    skip = (page - 1) * per_page
    return page, per_page, skip
