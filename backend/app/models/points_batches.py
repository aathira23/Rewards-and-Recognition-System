"""
Points Batches model - Tracks point expiry using FIFO.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class PointsBatch(Base):
    """Points batch model for managing point expiry."""
    
    __tablename__ = "points_batches"
    
    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    points = Column(Integer, nullable=False)
    remaining_points = Column(Integer, nullable=False)
    source_type = Column(String, nullable=False)  # ECARD, AWARD, CELEBRATION, MANAGER_REWARD
    source_id = Column(BigInteger, nullable=False)
    expiry_date = Column(Date, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User")
