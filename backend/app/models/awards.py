"""
Award model - Formal award nominations.
"""
from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Award(Base):
    """Award model for formal recognition nominations."""

    __tablename__ = "awards"

    id = Column(BigInteger, primary_key=True, index=True)
    nominee_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    nominator_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    award_type_id = Column(BigInteger, ForeignKey("award_types.id"), nullable=False)
    status = Column(String, nullable=False)  # PENDING, APPROVED, REJECTED
    points_awarded = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    nominee = relationship("User", foreign_keys=[nominee_id], back_populates="nominations_received")
    nominator = relationship("User", foreign_keys=[nominator_id], back_populates="nominations_made")
    award_type = relationship("AwardType", back_populates="awards")
    approvals = relationship("AwardApproval", back_populates="award")
