"""
Recognition Feed model - Activity feed for all recognitions.
"""
from sqlalchemy import Column, BigInteger, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class RecognitionFeed(Base):
    """Recognition feed model for activity stream."""
    
    __tablename__ = "recognition_feed"
    
    id = Column(BigInteger, primary_key=True, index=True)
    actor_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(BigInteger, ForeignKey("users.id"), nullable=True)
    source_type = Column(String, nullable=False)  # ECARD, AWARD, CELEBRATION, MANAGER_REWARD, CONVERSION
    source_id = Column(BigInteger, nullable=False)
    message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    actor = relationship("User", foreign_keys=[actor_id])
    receiver = relationship("User", foreign_keys=[receiver_id])
