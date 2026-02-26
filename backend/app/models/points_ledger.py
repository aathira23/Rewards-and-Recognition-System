"""
Points Ledger model - Transaction log for all point movements.
"""
from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class PointsLedger(Base):
    """Points ledger model for tracking all point transactions."""

    __tablename__ = "points_ledger"

    id = Column(BigInteger, primary_key=True, index=True)
    source_wallet_id = Column(BigInteger, ForeignKey("wallets.id"), nullable=True)
    target_wallet_id = Column(BigInteger, ForeignKey("wallets.id"), nullable=True)
    points = Column(Integer, nullable=False)
    transaction_type = Column(String, nullable=False)  # CREDIT, DEBIT
    reference_type = Column(String, nullable=True)  # ECARD, AWARD, REDEMPTION, CONVERSION
    reference_id = Column(BigInteger, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    source_wallet = relationship("Wallet", foreign_keys=[source_wallet_id], back_populates="ledger_source")
    target_wallet = relationship("Wallet", foreign_keys=[target_wallet_id], back_populates="ledger_target")
