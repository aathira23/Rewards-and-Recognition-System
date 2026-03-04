"""
Pydantic schemas for email operations.
Templates are file-based – no template schemas needed.
"""
from datetime import datetime
from typing import Optional, Dict, Any

from pydantic import BaseModel


# ---------------------------------------------------------------------------
# Test-send request
# ---------------------------------------------------------------------------

class SendTestEmailRequest(BaseModel):
    """Admin-only: render a template file and send a test email."""
    template_name: str          # e.g. "recognition_received" (no extension)
    to_email: str
    context: Dict[str, Any] = {}


# ---------------------------------------------------------------------------
# Email log (read-only)
# ---------------------------------------------------------------------------

class EmailLogResponse(BaseModel):
    id: int
    recipient_email: str
    template_key: str
    subject: str
    status: str          # QUEUED | SENT | FAILED
    error_message: Optional[str] = None
    created_at: datetime
    sent_at: Optional[datetime] = None

    class Config:
        from_attributes = True
