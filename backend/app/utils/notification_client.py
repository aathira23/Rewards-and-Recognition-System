"""
Notification Service client — thin HTTP wrapper around the Styria notification
microservice (Java/Spring Boot, port 9030).

Enabled when settings.USE_NOTIFICATION_SERVICE = True.
Teams channel is separately gated by settings.TEAMS_NOTIFICATIONS_ENABLED.

Usage::

    from app.utils.notification_client import send_email, send_teams

    send_email(to=["alice@example.com"], subject="You got points!", title="Points awarded",
               body="You just earned 500 points for your contribution.",
               token="<bearer-token>")

    send_teams(recipients=["alice@example.com"], title="Award approved",
               body="Your nomination has been approved. 🎉", token="<bearer-token>")

All functions are best-effort: they return True/False and never raise.
"""
from __future__ import annotations

import logging
from typing import Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

# Hard timeout so a slow/down notification service never blocks requests.
_TIMEOUT = 8.0
# The notification service Spring Boot controller maps to /notifications/send.
# (NotificationController: @RequestMapping("/notifications") + @PostMapping("/send"))
_SEND_ENDPOINT = "/notifications/send"


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _post(endpoint: str, payload: dict, token: Optional[str] = None) -> bool:
    """POST JSON to the notification service. Returns True on HTTP 200/201.

    Passes Authorization: Bearer <token> when provided — required by the
    Styria notification service in staging/production environments.
    """
    base = settings.NOTIFICATION_SERVICE_BASE_URL.rstrip("/")
    url = f"{base}/{endpoint.lstrip('/')}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token.strip()}"
    try:
        with httpx.Client(timeout=_TIMEOUT, verify=settings.NOTIFICATION_SERVICE_VERIFY_SSL) as client:
            resp = client.post(url, json=payload, headers=headers)
        if resp.status_code in (200, 201):
            return True
        logger.warning(
            "Notification service %s returned %s: %s",
            endpoint, resp.status_code, resp.text[:300],
        )
        return False
    except httpx.TimeoutException:
        logger.error("Notification service timed out calling %s", endpoint)
        return False
    except Exception as exc:
        logger.error("Notification service request failed (%s): %s", endpoint, exc)
        return False


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def send_email(
    to: list[str],
    subject: str,
    title: str,
    body: str,
    *,
    action_url: str = "",
    action_label: str = "View",
    sender_name: Optional[str] = None,
    additional_data: Optional[dict] = None,
    token: Optional[str] = None,
) -> bool:
    """
    Send an email through the notification service using the
    'common-notification' Thymeleaf template.

    Notification service maps:
        content.title          → mailTitle   (large heading in the email)
        content.body           → mailBody    (body paragraph)
        content.actionUrl      → url         (CTA button href, only shown if non-empty)
        content.actionLabel    → buttonLabel (CTA button text)
        content.additionalData → set as Thymeleaf context variables directly

    Args:
        additional_data: dict of extra template variables (e.g. sender_name,
                         badge_name, points) forwarded as content.additionalData.
        token:           Bearer token forwarded to the notification service
                         (required in Styria staging/production environments).
    """
    if not settings.USE_NOTIFICATION_SERVICE:
        logger.debug("send_email: USE_NOTIFICATION_SERVICE is False, skipping.")
        return False

    content: dict = {
        "title": title,
        "body": body,
        "actionUrl": action_url,
        "actionLabel": action_label,
    }
    if additional_data:
        content["additionalData"] = {k: str(v) for k, v in additional_data.items() if v is not None}

    payload: dict = {
        "channels": ["EMAIL"],
        "subject": subject,
        "templateName": "common-notification",
        "emailRecipients": to,
        "content": content,
    }
    if sender_name:
        payload["emailConfig"] = {"senderName": sender_name}

    return _post(_SEND_ENDPOINT, payload, token=token)


def send_teams(
    recipients: list[str],
    title: str,
    body: str,
    *,
    action_url: Optional[str] = None,
    token: Optional[str] = None,
) -> bool:
    """
    Send a Microsoft Teams message through the notification service.

    `recipients` should be corporate email addresses (e.g. alice@company.com).
    The notification service resolves these to Teams 1:1 chats via Graph API.
    """
    if not settings.USE_NOTIFICATION_SERVICE or not settings.TEAMS_NOTIFICATIONS_ENABLED:
        logger.debug("send_teams: skipping (USE_NOTIFICATION_SERVICE=%s, TEAMS_NOTIFICATIONS_ENABLED=%s)",
                      settings.USE_NOTIFICATION_SERVICE, settings.TEAMS_NOTIFICATIONS_ENABLED)
        return False

    content: dict = {"title": title, "body": body}
    if action_url:
        content["actionUrl"] = action_url
        content["actionLabel"] = "View"

    payload: dict = {
        "channels": ["TEAMS"],
        "subject": title,
        "teamsRecipients": recipients,
        "content": content,
    }
    if settings.TEAMS_TEAM_ID:
        payload["teamsConfig"] = {"teamId": settings.TEAMS_TEAM_ID}

    return _post(_SEND_ENDPOINT, payload, token=token)


def send_notification(
    *,
    to_emails: list[str],
    teams_recipients: Optional[list[str]] = None,
    subject: str,
    title: str,
    body: str,
    action_url: str = "",
    action_label: str = "View",
    sender_name: Optional[str] = None,
    additional_data: Optional[dict] = None,
    token: Optional[str] = None,
) -> bool:
    """
    Unified send: EMAIL + optional TEAMS in a single notification service call.
    This mirrors how the Styria training service fires notifications.
    Teams channel is only included when TEAMS_NOTIFICATIONS_ENABLED=True
    and `teams_recipients` is provided.
    """
    if not settings.USE_NOTIFICATION_SERVICE:
        return False

    channels = ["EMAIL"]
    if settings.TEAMS_NOTIFICATIONS_ENABLED and teams_recipients:
        channels.append("TEAMS")

    content: dict = {
        "title": title,
        "body": body,
        "actionUrl": action_url,
        "actionLabel": action_label,
    }
    if additional_data:
        content["additionalData"] = {k: str(v) for k, v in additional_data.items() if v is not None}

    payload: dict = {
        "channels": channels,
        "subject": subject,
        "templateName": "common-notification",
        "emailRecipients": to_emails,
        "content": content,
    }
    if teams_recipients and settings.TEAMS_NOTIFICATIONS_ENABLED:
        payload["teamsRecipients"] = teams_recipients
    if settings.TEAMS_TEAM_ID and settings.TEAMS_NOTIFICATIONS_ENABLED:
        payload["teamsConfig"] = {"teamId": settings.TEAMS_TEAM_ID}
    if sender_name:
        payload["emailConfig"] = {"senderName": sender_name}

    return _post(_SEND_ENDPOINT, payload, token=token)
