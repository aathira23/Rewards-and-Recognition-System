"""
Points Policy schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from decimal import Decimal
from pydantic import BaseModel


class PointsPolicyBase(BaseModel):
    """Base points policy schema."""
    recognition_type: str
    event_key: Optional[str] = None
    points: int
    monthly_limit: Optional[int] = None
    cooldown_days: Optional[int] = None
    conversion_rate: Optional[Decimal] = None
    conversion_reward_type: Optional[str] = None
    is_active: bool = True


class PointsPolicyCreate(PointsPolicyBase):
    """Schema for creating points policy."""
    pass


class PointsPolicyUpdate(BaseModel):
    """Schema for updating points policy."""
    points: Optional[int] = None
    monthly_limit: Optional[int] = None
    cooldown_days: Optional[int] = None
    conversion_rate: Optional[Decimal] = None
    is_active: Optional[bool] = None


class PointsPolicyResponse(PointsPolicyBase):
    """Schema for points policy response."""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
