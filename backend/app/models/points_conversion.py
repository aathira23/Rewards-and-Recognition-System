"""
Points Conversion model - Payroll encashment and CSR donations.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Numeric, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class PointsConversion(Base):
    """Points conversion model for encashment and donations."""

    __tablename__ = "points_conversion"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    points_converted = Column(Integer, nullable=False)
    cash_amount = Column(Numeric(10, 2), nullable=False)
    conversion_type = Column(String, nullable=False)  # PAYROLL, CSR, VOUCHER
    status = Column(String, nullable=False)  # PENDING, APPROVED, REJECTED, PAID
    requested_at = Column(DateTime(timezone=True), server_default=func.now())
    approved_by = Column(BigInteger, ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="conversions")
    approver = relationship("User", foreign_keys=[approved_by])
