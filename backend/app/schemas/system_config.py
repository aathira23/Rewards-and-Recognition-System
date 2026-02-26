"""
System Config schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class SystemConfigBase(BaseModel):
    """Base config schema."""
    key: str
    value: str
    description: Optional[str] = None


class SystemConfigResponse(SystemConfigBase):
    """Schema for config response."""
    updated_at: datetime

    class Config:
        from_attributes = True


class SystemConfigUpdate(BaseModel):
    """Schema for updating a config."""
    value: str
    description: Optional[str] = None
