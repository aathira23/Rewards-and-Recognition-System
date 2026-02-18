"""
Reward model - Store catalog items.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Reward(Base):
    """Reward model for store catalog items."""

    __tablename__ = "rewards"

    id = Column(BigInteger, primary_key=True, index=True)
    name = Column(String, nullable=False)
    reward_type = Column(String, nullable=False)  # MERCH, GIFT_CARD, CSR
    points_required = Column(Integer, nullable=False)
    stock_quantity = Column(Integer, nullable=True)  # NULL = unlimited
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    redemptions = relationship("Redemption", back_populates="reward")
