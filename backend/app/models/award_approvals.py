"""
Award Approval model - Multi-level approval workflow.
"""
from sqlalchemy import Column, BigInteger, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class AwardApproval(Base):
    """Award approval model for multi-level approval workflow."""

    __tablename__ = "award_approvals"

    id = Column(BigInteger, primary_key=True, index=True)
    award_id = Column(BigInteger, ForeignKey("awards.id"), nullable=False)
    approver_id = Column(BigInteger, nullable=False)
    approval_level = Column(String, nullable=False)  # MANAGER, DEPT_HEAD, HR
    status = Column(String, nullable=False)  # APPROVED, REJECTED
    comments = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    award = relationship("Award", back_populates="approvals")
