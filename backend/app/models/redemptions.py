"""
Redemption model - Reward purchase transactions.
"""
from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Redemption(Base):
    """Redemption model for reward purchases."""
    
    __tablename__ = "redemptions"
    
    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    reward_id = Column(BigInteger, ForeignKey("rewards.id"), nullable=False)
    points_used = Column(Integer, nullable=False)
    status = Column(String, nullable=False)  # REQUESTED, FULFILLED, CANCELLED
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="redemptions")
    reward = relationship("Reward", back_populates="redemptions")
