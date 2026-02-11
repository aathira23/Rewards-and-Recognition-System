"""
Points Batches schemas for request/response validation.
"""
from datetime import date, datetime
from pydantic import BaseModel


class PointsBatchBase(BaseModel):
    """Base points batch schema."""
    points: int
    remaining_points: int
    source_type: str
    source_id: int
    expiry_date: date


class PointsBatchResponse(PointsBatchBase):
    """Schema for points batch response."""
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
