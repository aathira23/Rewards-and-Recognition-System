"""
Email management API endpoints.

Templates are now static files – no CRUD needed.
Provides:
  GET  /email/logs          – view email send history (HR only)
  POST /email/test-send     – send a test email (HR only)
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.schemas.email import (
    EmailLogResponse,
    SendTestEmailRequest,
)
from app.services.email_service import EmailService
from app.utils.response import success, client_error
from app.utils.constants import (
    DEFAULT_PAGE_SIZE,
    ERROR_ACCESS_DENIED,
    SUCCESS_EMAIL_LOGS_RETRIEVED,
    SUCCESS_TEST_EMAIL_DISPATCHED,
)

router = APIRouter()


# ───────────────────────────── Email Logs ─────────────────────────────

@router.get("/logs")
def list_email_logs(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """View email send history (HR only)."""
    if current_user.role != "HR":
        return client_error(message=ERROR_ACCESS_DENIED, status_code=403)

    from app.utils.constants import clamp_pagination
    page, per_page, skip = clamp_pagination(page, per_page)

    svc = EmailService(db)
    logs = svc.get_email_logs(limit=per_page, offset=skip)
    data = [EmailLogResponse.model_validate(l) for l in logs]
    return success(data=data, message=SUCCESS_EMAIL_LOGS_RETRIEVED)


# ───────────────────────────── Test Send ─────────────────────────────

@router.post("/test-send")
def test_send_email(
    body: SendTestEmailRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Render a template file and send a test email (HR only)."""
    if current_user.role != "HR":
        return client_error(message=ERROR_ACCESS_DENIED, status_code=403)

    svc = EmailService(db)
    log = svc.send_to_email(
        to_email=body.to_email,
        template_name=body.template_name,
        context=body.context,
    )
    if log is None:
        return client_error(message="Template file not found or send failed.", status_code=422)
    return success(data={"status": log.status, "log_id": log.id}, message=SUCCESS_TEST_EMAIL_DISPATCHED)
