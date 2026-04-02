"""
Award model - Formal award nominations.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Award(Base):
    """Award model for formal recognition nominations."""

    __tablename__ = "awards"

    id = Column(BigInteger, primary_key=True, index=True)
    nominee_id = Column(BigInteger, nullable=False)
    nominator_id = Column(BigInteger, nullable=False)
    award_type_id = Column(BigInteger, ForeignKey("award_types.id"), nullable=False)
    status = Column(String, nullable=False)  # PENDING, APPROVED, REJECTED
    points_awarded = Column(Integer, nullable=True)
    citation = Column(Text, nullable=True)
    persona_type = Column(String, nullable=True)   # PERSONAL | DEPARTMENT | Company
    persona_label = Column(String, nullable=True)  # e.g. "HR Department" / "Tarento"
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    award_type = relationship("AwardType", back_populates="awards")
    approvals = relationship("AwardApproval", back_populates="award")
