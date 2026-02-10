"""
Award Approval schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class AwardApprovalBase(BaseModel):
    """Base award approval schema."""
    approval_level: str
    status: str
    comments: Optional[str] = None


class AwardApprovalResponse(AwardApprovalBase):
    """Schema for award approval response."""
    id: int
    award_id: int
    approver_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True
