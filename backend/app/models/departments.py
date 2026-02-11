"""
Department model.
"""
from sqlalchemy import Column, BigInteger, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Department(Base):
    """Department model for organizational structure."""

    __tablename__ = "departments"

    id = Column(BigInteger, primary_key=True, index=True)
    name = Column(String, nullable=False)

    # Relationships
    users = relationship("User", back_populates="department")
