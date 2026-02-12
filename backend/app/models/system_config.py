"""
System Config model - Global configuration settings.
"""
from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.sql import func

from app.core.database import Base


class SystemConfig(Base):
    """System configuration model for global settings."""

    __tablename__ = "system_config"

    key = Column(String, primary_key=True, index=True)
    value = Column(Text, nullable=False)
    description = Column(Text, nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
