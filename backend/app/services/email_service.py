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
# Use only ASCII punctuation so notification service doesn't garble en-dashes.
# ---------------------------------------------------------------------------
TEMPLATE_SUBJECTS: Dict[str, str] = {
    "welcome":               "Welcome to {{ org_name }}!",
    "verify_email":          "Verify your email address - {{ org_name }}",
    "password_reset":        "Reset your {{ org_name }} password",
    "award_decision":        "{{ item_type }} - {{ status }}",
    "conversion_decision":   "Points Conversion - {{ status }}",
    "nomination_submitted":  "Award Nomination Submitted - {{ org_name }}",
    "redemption_receipt":    "Redemption confirmed - {{ reward_name }}",
    "conversion_submitted":  "Points conversion submitted - {{ org_name }}",
    "points_expiry":         "Your points expire on {{ expiry_date }}",
    "celebration_reminder":  "{{ event_type }}: {{ colleague_name }} - {{ org_name }}",
    "pending_approvals":     "You have {{ pending_count }} pending approval(s)",
    "recognition_received":  "{{ sender_name }} recognised you!",
    "hr_critical":           "[HR Alert] {{ short_reason }}",
}

# ---------------------------------------------------------------------------
# Clean titles & body text sent to the Styria notification service.
# The NS renders these inside its own branded template, so we keep them
# short and plain — no HTML, no entities.
# ---------------------------------------------------------------------------
_NS_TITLES: Dict[str, str] = {
    "welcome":               "Welcome to {{ org_name }}!",
    "verify_email":          "Verify Your Email Address",
    "password_reset":        "Password Reset Request",
    "award_decision":        "{{ item_type }} - {{ status }}",
    "conversion_decision":   "Points Conversion {{ status }}",
    "nomination_submitted":  "Nomination Submitted",
    "redemption_receipt":    "Redemption Confirmed - {{ reward_name }}",
    "conversion_submitted":  "Conversion Request Received",
    "points_expiry":         "Your Points Are Expiring Soon",
    "celebration_reminder":  "{{ event_type }}: {{ colleague_name }}",
    "pending_approvals":     "Pending Approvals Reminder",
    "recognition_received":  "You've Been Recognised!",
    "hr_critical":           "[HR Alert] {{ short_reason }}",
}

_NS_BODIES: Dict[str, str] = {
    "welcome":
        "Hi {{ user_name }}, welcome to {{ org_name }}! "
        "Your account is ready. Log in to start earning and redeeming points.",
    "verify_email":
        "Hi {{ user_name }}, please verify your email address to activate your account.",
    "password_reset":
        "Hi {{ user_name }}, a password reset was requested for your account. "
        "If this wasn't you, you can ignore this message.",
    "award_decision":
        "Hi {{ user_name }}, your {{ item_type | lower }} nomination has been {{ status | lower }}"
        "{% if comment %}: {{ comment }}{% endif %}.",
    "conversion_decision":
        "Hi {{ user_name }}, your request to convert {{ points_amount }} points has been "
        "{{ status | lower }}{% if comment %}: {{ comment }}{% endif %}.",
    "nomination_submitted":
        "Hi {{ user_name }}, your award nomination has been submitted and is awaiting review.",
    "redemption_receipt":
        "Hi {{ user_name }}, your redemption of {{ reward_name }} for {{ points_used }} points "
        "is confirmed and being processed. "
        "Your remaining balance is {{ remaining_balance }} pts.",
    "conversion_submitted":
        "Hi {{ user_name }}, your request to convert {{ points }} points to cash "
        "({{ cash_amount }}) has been received and is pending HR approval.",
    "points_expiry":
        "Hi {{ user_name }}, {{ points }} of your points will expire on {{ expiry_date }} "
        "({{ days_left }} day(s) away). Head to the store to spend them!",
    "celebration_reminder":
        "A reminder that {{ colleague_name }} has a {{ event_type | lower }} coming up. "
        "Log in to send them a celebration!",
    "pending_approvals":
        "Hi {{ user_name }}, you have {{ pending_count }} pending award nomination(s) "
        "waiting for your review.",
    "recognition_received":
        "{{ sender_name }} has recognised you"
        "{% if badge_name %} with '{{ badge_name }}'{% endif %}"
        "{% if message %} - {{ message }}{% endif %}.",
    "hr_critical":
        "{{ short_reason }}"
        "{% if detailed_message %}: {{ detailed_message }}{% endif %}",
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

                # Build a clean short title for the NS branded template.
                ns_title = subject  # safe fallback
                ns_title_tpl = _NS_TITLES.get(template_name)
                if ns_title_tpl and ctx:
                    try:
                        ns_title = _jinja_env.from_string(ns_title_tpl).render(**ctx)
                    except Exception:
                        pass

                # Build a clean plain-text body for the NS branded template.
                # Prefer per-template body string; fall back to stripping our HTML.
                ns_body_tpl = _NS_BODIES.get(template_name)
                if ns_body_tpl and ctx:
                    try:
                        ns_body = _jinja_env.from_string(ns_body_tpl).render(**ctx)
                    except Exception:
                        ns_body = None
                else:
                    ns_body = None
                if not ns_body:
                    import html as _html
                    # Strip <head> section first so title/meta don't pollute the body
                    stripped = re.sub(r"(?is)<head[^>]*>.*?</head>", "", body_html)
                    stripped = re.sub(r"<[^>]+>", " ", stripped)
                    ns_body = " ".join(_html.unescape(stripped).split())[:500]

                action_url = ctx.get("frontend_url", settings.FRONTEND_URL) if ctx else settings.FRONTEND_URL
                ok = ns_send(
                    to_emails=[to_email],
                    teams_recipients=[to_email] if settings.TEAMS_NOTIFICATIONS_ENABLED else None,
                    subject=subject,
                    title=ns_title,
                    body=ns_body,
                    action_url=action_url,
                    action_label="Open Dashboard",
                    sender_name=settings.SMTP_FROM_NAME,
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
