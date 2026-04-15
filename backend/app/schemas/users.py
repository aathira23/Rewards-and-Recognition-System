"""
User schemas for request/response validation.
"""
from pydantic import BaseModel


class CacheFlushRequest(BaseModel):
    """Schema for manual cache flush request."""
    scope: str = "all"  # "all", "profiles", "auth"
