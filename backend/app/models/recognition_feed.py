"""
Recognition Feed model - Activity feed for all recognitions.
"""
from sqlalchemy import Column, BigInteger, String, Text, DateTime
from sqlalchemy.sql import func

from app.core.database import Base


class RecognitionFeed(Base):
    """Recognition feed model for activity stream."""

    __tablename__ = "recognition_feed"

    id = Column(BigInteger, primary_key=True, index=True)
    actor_id = Column(BigInteger, nullable=False)
    receiver_id = Column(BigInteger, nullable=True)
    source_type = Column(String, nullable=False)  # ECARD, AWARD, CELEBRATION, MANAGER_REWARD, CONVERSION
    source_id = Column(BigInteger, nullable=False)
    message = Column(Text, nullable=True)
    actor_label = Column(String(120), nullable=True)  # persona display name override
    created_at = Column(DateTime(timezone=True), server_default=func.now())
