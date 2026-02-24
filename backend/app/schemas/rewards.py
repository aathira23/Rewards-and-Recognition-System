"""
Reward schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class RewardBase(BaseModel):
    """Base reward schema."""
    name: str
    reward_type: str
    points_required: int
    stock_quantity: Optional[int] = None  # NULL = unlimited stock
    image_url: Optional[str] = None
    is_active: bool = True


class RewardCreate(RewardBase):
    """Schema for creating a reward."""
    pass


class RewardUpdate(BaseModel):
    """Schema for updating a reward."""
    name: Optional[str] = None
    reward_type: Optional[str] = None
    points_required: Optional[int] = None
    stock_quantity: Optional[int] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None


class RewardResponse(RewardBase):
    """Schema for reward response."""
    id: int
    stock_quantity: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
