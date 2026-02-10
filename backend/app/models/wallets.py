"""
Wallet model - Manages point balances for users and managers.
"""
from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Wallet(Base):
    """Wallet model for storing point balances."""
    
    __tablename__ = "wallets"
    
    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    wallet_type = Column(String, nullable=False)  # EMPLOYEE, MANAGER, SYSTEM
    balance = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="wallets")
    funding_records = relationship("WalletFunding", back_populates="manager_wallet")
    ledger_source = relationship("PointsLedger", foreign_keys="PointsLedger.source_wallet_id", back_populates="source_wallet")
    ledger_target = relationship("PointsLedger", foreign_keys="PointsLedger.target_wallet_id", back_populates="target_wallet")
