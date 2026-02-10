"""
Notification model - User notifications.
"""
from sqlalchemy import Column, BigInteger, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Notification(Base):
    """Notification model for user alerts."""
    
    __tablename__ = "notifications"
    
    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    source_type = Column(String, nullable=False)  # ECARD, AWARD, REDEMPTION, CONVERSION
    source_id = Column(BigInteger, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="notifications")
