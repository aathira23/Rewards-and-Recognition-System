"""
EmailLog model – audit trail for every email the system sends or attempts.
"""
from sqlalchemy import Column, BigInteger, String, Text, DateTime
from sqlalchemy.sql import func

from app.core.database import Base


class EmailLog(Base):
    """Immutable log of every email dispatch attempt."""

    __tablename__ = "email_logs"

    id = Column(BigInteger, primary_key=True, index=True)
    recipient_email = Column(String, nullable=False, index=True)
    user_id = Column(BigInteger, nullable=True, index=True)       # FK to users; nullable for external
    template_key = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    body_html = Column(Text, nullable=True)
    status = Column(String, nullable=False, default="QUEUED")     # QUEUED | SENT | FAILED
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    sent_at = Column(DateTime(timezone=True), nullable=True)
