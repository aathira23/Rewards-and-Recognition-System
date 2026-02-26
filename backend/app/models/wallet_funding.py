"""
Wallet Funding model - Tracks HR allocations to manager wallets.
"""
from sqlalchemy import Column, BigInteger, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class WalletFunding(Base):
    """Wallet funding model for manager budget allocations."""

    __tablename__ = "wallet_funding"

    id = Column(BigInteger, primary_key=True, index=True)
    manager_wallet_id = Column(BigInteger, ForeignKey("wallets.id"), nullable=False)
    funded_by = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    points = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    manager_wallet = relationship("Wallet", back_populates="funding_records")
    funder = relationship("User")
