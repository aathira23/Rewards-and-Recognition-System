"""
User model - Core user entity.
"""
from sqlalchemy import Column, BigInteger, String, Boolean, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    """User model representing employees, managers, and admins."""

    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    password = Column(String, nullable=False)
    role = Column(String, nullable=False, default="UNKNOWN")  # EMPLOYEE, MANAGER, DEPT_HEAD, HR
    department_id = Column(BigInteger, ForeignKey("departments.id"), nullable=True)
    manager_id = Column(BigInteger, ForeignKey("users.id"), nullable=True)
    date_of_joining = Column(Date, nullable=True)
    birth_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    department = relationship("Department", back_populates="users")
    manager = relationship("User", remote_side=[id], backref="subordinates")
    email_notifications_enabled = Column(Boolean, nullable=False, default=True)
