"""
ECard model - Peer-to-peer recognition cards.
"""
from sqlalchemy import Column, BigInteger, Integer, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class ECard(Base):
    """ECard model for peer recognition."""

    __tablename__ = "ecards"

    id = Column(BigInteger, primary_key=True, index=True)
    sender_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    badge_id = Column(BigInteger, ForeignKey("badges.id"), nullable=False)
    points_awarded = Column(Integer, nullable=False)
    message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_ecards")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="received_ecards")
    badge = relationship("Badge", back_populates="ecards")
