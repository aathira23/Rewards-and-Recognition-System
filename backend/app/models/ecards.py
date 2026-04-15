"""
ECard model - Peer-to-peer recognition cards.
"""
from sqlalchemy import Column, BigInteger, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class ECard(Base):
    """ECard model for peer recognition."""

    __tablename__ = "ecards"

    id = Column(BigInteger, primary_key=True, index=True)
    sender_id = Column(BigInteger, nullable=False)
    receiver_id = Column(BigInteger, nullable=False)
    badge_id = Column(BigInteger, ForeignKey("badges.id"), nullable=False)
    points_awarded = Column(Integer, nullable=False)
    message = Column(Text, nullable=True)
    persona_type = Column(String(20), nullable=False, server_default="PERSONAL")  # PERSONAL | DEPARTMENT
    persona_label = Column(String(120), nullable=True)  # e.g. "HR Department"
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    badge = relationship("Badge", back_populates="ecards")
