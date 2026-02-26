"""
Points Policy model - Configuration for point values and rules.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Numeric, Boolean, DateTime
from sqlalchemy.sql import func

from app.core.database import Base


class PointsPolicy(Base):
    """Points policy model for configuring recognition point values."""

    __tablename__ = "points_policy"

    id = Column(BigInteger, primary_key=True, index=True)
    recognition_type = Column(String, nullable=False)  # ECARD, AWARD, CELEBRATION
    event_key = Column(String, nullable=True)  # BIRTHDAY, ANNIVERSARY, STAR_PERFORMER
    points = Column(Integer, nullable=False)
    monthly_limit = Column(Integer, nullable=True)
    cooldown_days = Column(Integer, nullable=True)
    conversion_rate = Column(Numeric(10, 2), nullable=True)
    conversion_reward_type = Column(String, nullable=True)  # PAYROLL, CSR, VOUCHER
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


