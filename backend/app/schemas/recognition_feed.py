"""
Recognition Feed schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class RecognitionFeedBase(BaseModel):
    """Base recognition feed schema."""
    source_type: str
    source_id: int
    message: Optional[str] = None


class RecognitionFeedResponse(RecognitionFeedBase):
    """Schema for recognition feed response."""
    id: int
    actor_id: int
    receiver_id: Optional[int] = None
    created_at: datetime

    actor: Optional["UserShortResponse"] = None
    receiver: Optional["UserShortResponse"] = None

    class Config:
        from_attributes = True

from app.schemas.ecards import UserShortResponse
RecognitionFeedResponse.model_rebuild()
