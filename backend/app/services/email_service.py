"""
EmailService – renders Jinja2 templates from files and sends emails via SMTP.

Templates live in  app/templates/email/<name>.html  (and optional .txt).
Subject lines are defined in  TEMPLATE_SUBJECTS  below – edit freely.

Usage::

    from app.services.email_service import EmailService
    email_svc = EmailService(db)
    email_svc.send(
        event_type=EmailEventType.RECOGNITION_RECEIVED,
        recipient_user_id=42,
        context={"sender_name": "Alice", "badge_name": "Star"},
    )
"""
from __future__ import annotations

import logging
import os
import re
import smtplib
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Any, Dict, Optional

from jinja2 import Environment, FileSystemLoader, select_autoescape
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.email_logs import EmailLog
from app.utils.enums import EmailEventType
from app.repository.email_repository import EmailRepository

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Template directory:  app/services/../templates/email/
# ---------------------------------------------------------------------------
_TEMPLATE_DIR = os.path.join(os.path.dirname(__file__), "..", "templates", "email")

_jinja_env = Environment(
    loader=FileSystemLoader(_TEMPLATE_DIR),
    autoescape=select_autoescape(["html"]),
)

# ---------------------------------------------------------------------------
# Subject lines (Jinja2 strings, rendered with the same context as the body)
# ---------------------------------------------------------------------------
TEMPLATE_SUBJECTS: Dict[str, str] = {
    "welcome":               "Welcome to {{ org_name }}!",
    "verify_email":          "Verify your email address – {{ org_name }}",
    "password_reset":        "Reset your {{ org_name }} password",
    "award_decision":        "{{ item_type }} – {{ status }}",
    "conversion_decision":   "Points Conversion – {{ status }}",
    "nomination_submitted":  "Award Nomination Submitted – {{ org_name }}",
    "redemption_receipt":    "Redemption confirmed – {{ reward_name }}",
    "conversion_submitted":  "Points conversion submitted – {{ org_name }}",
    "points_expiry":         "⚠ Your points expire on {{ expiry_date }}",
    "celebration_reminder":  "{{ event_type }}: {{ colleague_name }} – {{ org_name }}",
    "pending_approvals":     "You have {{ pending_count }} pending approval(s)",
    "recognition_received":  "{{ sender_name }} recognised you!",
    "hr_critical":           "[HR Alert] {{ short_reason }}",
}

# ---------------------------------------------------------------------------
# Map EmailEventType → template file name (without extension)
# ---------------------------------------------------------------------------
EVENT_TEMPLATE_MAP: Dict[str, str] = {
    EmailEventType.WELCOME:                    "welcome",
    EmailEventType.EMAIL_VERIFICATION:         "verify_email",
    EmailEventType.PASSWORD_RESET:             "password_reset",
    EmailEventType.NOMINATION_SUBMITTED:       "nomination_submitted",
    EmailEventType.AWARD_APPROVED:             "award_decision",
    EmailEventType.AWARD_REJECTED:             "award_decision",
    EmailEventType.REDEMPTION_CONFIRMED:       "redemption_receipt",
    EmailEventType.CONVERSION_SUBMITTED:       "conversion_submitted",
    EmailEventType.CONVERSION_APPROVED:        "conversion_decision",
    EmailEventType.CONVERSION_REJECTED:        "conversion_decision",
    EmailEventType.POINTS_EXPIRY_REMINDER:     "points_expiry",
    EmailEventType.CELEBRATION_REMINDER:       "celebration_reminder",
    EmailEventType.PENDING_APPROVALS_REMINDER: "pending_approvals",
    EmailEventType.RECOGNITION_RECEIVED:       "recognition_received",
    EmailEventType.HR_CRITICAL:                "hr_critical",
}


class EmailService:
    """Render file-based Jinja2 templates and dispatch via SMTP."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = EmailRepository(db)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def send(
        self,
        event_type: str,
        recipient_user_id: int,
        context: Dict[str, Any],
        *,
        force: bool = False,
    ) -> Optional[EmailLog]:
        """Resolve template, check preferences, render and dispatch."""
        if not force and not self.repository.is_email_enabled():
            logger.debug("Email notifications globally disabled – skipping.")
            return None

        user = self.repository.get_user_by_id(recipient_user_id)
        if not user:
            # Fallback: resolve via User Service when token is available
            if self._token:
                from app.services.user_profiles_client import get_user_profile
                profile = get_user_profile(recipient_user_id, self._token)
                if profile and profile.email:
                    # User not stored locally — treat notifications as enabled
                    ctx = {
                        "user_name": profile.name,
                        "org_name": settings.APP_NAME,
                        "frontend_url": settings.FRONTEND_URL,
                        "manage_prefs_url": f"{settings.FRONTEND_URL}/settings/notifications",
                        "support_email": settings.SMTP_FROM_EMAIL,
                        **context,
                    }
                    template_name = EVENT_TEMPLATE_MAP.get(event_type)
                    if not template_name:
                        logger.error("No template mapping for event_type=%s", event_type)
                        return None
                    subject, body_html, body_text = self._render_template(template_name, ctx)
                    return self._dispatch(
                        to_email=profile.email,
                        user_id=recipient_user_id,
                        template_name=template_name,
                        subject=subject,
                        body_html=body_html,
                        body_text=body_text,
                        ctx=ctx,
                        token=self._token,
                    )
            logger.warning("EmailService.send: user %s not found", recipient_user_id)
            return None

        if not force and not user.email_notifications_enabled:
            logger.debug("User %s opted out of email notifications", user.id)
            return None

        template_name = EVENT_TEMPLATE_MAP.get(event_type)
        if not template_name:
            logger.error("No template mapping for event_type=%s", event_type)
            return None

        ctx = {
            "user_name": user.name,
            "org_name": settings.APP_NAME,
            "frontend_url": settings.FRONTEND_URL,
            "manage_prefs_url": f"{settings.FRONTEND_URL}/settings/notifications",
            "support_email": settings.SMTP_FROM_EMAIL,
            **context,
        }

        subject, body_html, body_text = self._render_template(template_name, ctx)
        return self._dispatch(
            to_email=user.email,
            user_id=user.id,
            template_name=template_name,
            subject=subject,
            body_html=body_html,
            body_text=body_text,
            ctx=ctx,
            token=self._token,
        )

    def send_to_email(
        self,
        to_email: str,
        template_name: str,
        context: Dict[str, Any],
    ) -> Optional[EmailLog]:
        """Low-level: send to any email address (admin test / external use)."""
        ctx = {
            "org_name": settings.APP_NAME,
            "frontend_url": settings.FRONTEND_URL,
            "support_email": settings.SMTP_FROM_EMAIL,
            **context,
        }
        subject, body_html, body_text = self._render_template(template_name, ctx)
        return self._dispatch(
            to_email=to_email,
            user_id=None,
            template_name=template_name,
            subject=subject,
            body_html=body_html,
            body_text=body_text,
            ctx=ctx,
        )

    # ------------------------------------------------------------------
    # Email log helpers (used by the API layer)
    # ------------------------------------------------------------------

    def get_email_logs(self, limit: int = 50, offset: int = 0):
        return self.repository.get_logs(limit, offset)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _render_template(self, name: str, ctx: dict):
        """Returns (subject, body_html, body_text | None)."""
        raw_subject = TEMPLATE_SUBJECTS.get(name, "{{ org_name }} Notification")
        subject = _jinja_env.from_string(raw_subject).render(**ctx)

        try:
            body_html = _jinja_env.get_template(f"{name}.html").render(**ctx)
        except Exception as exc:
            logger.error("Failed to render '%s.html': %s", name, exc)
            body_html = f"<p>{subject}</p>"

        body_text: Optional[str] = None
        try:
            body_text = _jinja_env.get_template(f"{name}.txt").render(**ctx)
        except Exception:
            pass  # plain-text file is optional

        return subject, body_html, body_text

    def _dispatch(
        self,
        *,
        to_email: str,
        user_id: Optional[int],
        template_name: str,
        subject: str,
        body_html: str,
        body_text: Optional[str],
        ctx: Optional[Dict[str, Any]] = None,
        token: Optional[str] = None,
    ) -> EmailLog:
        log = self.repository.create_log(
            recipient_email=to_email,
            user_id=user_id,
            template_key=template_name,
            subject=subject,
            body_html=body_html,
            status="QUEUED",
        )

        try:
            # ── Route through Styria notification service ──────────────────
            if settings.USE_NOTIFICATION_SERVICE:
                from app.utils.notification_client import send_notification as ns_send
                # Derive a plain-text body: prefer .txt template, else strip HTML tags.
                plain_body = (
                    body_text
                    or re.sub(r"<[^>]+>", " ", body_html).strip()[:600]
                )
                action_url = ctx.get("frontend_url", settings.FRONTEND_URL) if ctx else settings.FRONTEND_URL
                # Single API call to notification service: EMAIL + optional TEAMS.
                # When TEAMS_NOTIFICATIONS_ENABLED, the recipient's corporate email
                # is also used as the Teams recipient — the NS resolves it to a DM.
                ok = ns_send(
                    to_emails=[to_email],
                    teams_recipients=[to_email] if settings.TEAMS_NOTIFICATIONS_ENABLED else None,
                    subject=subject,
                    title=subject,
                    body=plain_body,
                    action_url=action_url,
                    action_label="Open Dashboard",
                    sender_name=settings.SMTP_FROM_NAME,
                    additional_data=ctx,
                    token=token or self._token,
                )
                if ok:
                    log.status = "SENT"
                    log.sent_at = datetime.now(timezone.utc)
                    logger.info(
                        "Email sent via notification service to %s [%s]",
                        to_email, template_name,
                    )
                else:
                    log.status = "FAILED"
                    log.error_message = "Notification service returned a failure response"
                    logger.warning(
                        "Notification service failed for %s [%s]", to_email, template_name
                    )

            # ── Direct SMTP (dev / fallback) ───────────────────────────────
            else:
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject
                msg["From"] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
                msg["To"] = to_email

                if body_text:
                    msg.attach(MIMEText(body_text, "plain"))
                msg.attach(MIMEText(body_html, "html"))

                server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10)
                server.ehlo()
                if settings.SMTP_USE_TLS:
                    server.starttls()
                    server.ehlo()  # re-identify after STARTTLS

                if settings.SMTP_USERNAME:
                    server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)

                server.sendmail(settings.SMTP_FROM_EMAIL, [to_email], msg.as_string())
                server.quit()

                log.status = "SENT"
                log.sent_at = datetime.now(timezone.utc)
                logger.info("Email sent to %s [%s]", to_email, template_name)

        except Exception as exc:
            log.status = "FAILED"
            log.error_message = str(exc)[:500]
            logger.exception("Failed to send email to %s: %s", to_email, exc)

        self.repository.commit()
        self.repository.refresh(log)
        return log
