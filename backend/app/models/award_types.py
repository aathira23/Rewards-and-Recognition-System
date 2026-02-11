"""
Award Type model - Defines available award categories.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Text, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class AwardType(Base):
    """Award type model for defining award categories."""

    __tablename__ = "award_types"

    id = Column(BigInteger, primary_key=True, index=True)
    award_key = Column(String, unique=True, nullable=False)  # STAR_PERFORMER, TEAM_EXCELLENCE
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    points = Column(Integer, nullable=False)
    frequency = Column(String, nullable=False)  # MONTHLY, QUARTERLY, ADHOC
    eligibility_rule = Column(String, nullable=False)  # MANAGER_ONLY, PEER, CROSS_DEPT
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    awards = relationship("Award", back_populates="award_type")
