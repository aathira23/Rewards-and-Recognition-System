"""
Award schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class _UserBrief(BaseModel):
    """Minimal user info embedded in award responses."""
    id: int
    name: str

    class Config:
        from_attributes = True


class _AwardTypeBrief(BaseModel):
    """Minimal award-type info embedded in award responses."""
    id: int
    name: str

    class Config:
        from_attributes = True


class AwardBase(BaseModel):
    """Base award schema."""
    award_type_id: int


class AwardNominationCreate(AwardBase):
    """Schema for creating an award nomination."""
    nominee_id: int
    citation: Optional[str] = None
    persona_type: Optional[str] = None   # PERSONAL | DEPARTMENT | Company
    persona_label: Optional[str] = None  # e.g. "HR Department"


class AwardResponse(AwardBase):
    """Schema for award response."""
    id: int
    nominee_id: int
    nominator_id: int
    status: str
    points_awarded: Optional[int]
    citation: Optional[str] = None
    persona_type: Optional[str] = None
    persona_label: Optional[str] = None
    next_required_level: Optional[str] = None
    created_at: datetime

    # Nested objects – populated via SQLAlchemy relationships
    nominee: Optional[_UserBrief] = None
    nominator: Optional[_UserBrief] = None
    award_type: Optional[_AwardTypeBrief] = None

    # Latest human reviewer info (set dynamically in service)
    reviewer_comment: Optional[str] = None
    reviewer_name: Optional[str] = None
    reviewer_level: Optional[str] = None

    class Config:
        from_attributes = True


class AwardActionRequest(BaseModel):
    """Schema for approving/rejecting award."""
    action: str  # APPROVE, REJECT
    comments: Optional[str] = None


class ApprovalHistoryItem(BaseModel):
    """One entry in a user's approval history — award info + their action."""
    # Approval record fields
    my_action: str           # APPROVED or REJECTED
    my_action_at: datetime
    my_level: str            # MANAGER / DEPT_HEAD / HR
    my_comments: Optional[str] = None

    # Nomination / award fields
    nomination_id: int
    nominee_id: int
    nominator_id: int
    award_type_name: str
    points_awarded: Optional[int] = None
    citation: Optional[str] = None
    nomination_status: str   # PENDING / APPROVED / REJECTED (final overall status)
    nominee_name: str
    nominator_name: str
    created_at: datetime

    class Config:
        from_attributes = True
