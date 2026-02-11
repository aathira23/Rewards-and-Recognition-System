"""
Celebration model - Automated birthday and anniversary recognition.
"""
from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Celebration(Base):
    """Celebration model for automated recognition events."""

    __tablename__ = "celebrations"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    celebration_type = Column(String, nullable=False)  # BIRTHDAY, ANNIVERSARY
    year = Column(Integer, nullable=False)
    points_awarded = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="celebrations")
