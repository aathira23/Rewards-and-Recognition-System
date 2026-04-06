"""
Background email dispatcher – fires email sends in a separate thread so
the main request is not blocked by network I/O.

Usage (from any service / API handler):

    from app.jobs.email_worker import enqueue_email

    enqueue_email(
        event_type="RECOGNITION_RECEIVED",
        recipient_user_id=42,
        context={"sender_name": "Alice", "badge_name": "Star"},
    )

The worker opens its own DB session, renders the template, and sends
synchronously inside the thread.  For high-volume production setups this
can be swapped out for Celery + Redis with almost no API change.
"""
from __future__ import annotations

import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)

# Thread pool shared across the application lifetime.
_pool = ThreadPoolExecutor(max_workers=4, thread_name_prefix="email-worker")


def enqueue_email(
    event_type: str,
    recipient_user_id: int,
    context: Dict[str, Any],
    *,
    force: bool = False,
    token: Optional[str] = None,
) -> None:
    """Submit an email send job to the background thread pool."""
    _pool.submit(_send_email_task, event_type, recipient_user_id, context, force, token)


def _send_email_task(
    event_type: str,
    recipient_user_id: int,
    context: Dict[str, Any],
    force: bool,
    token: Optional[str],
) -> None:
    """Executed inside a worker thread – opens its own DB session."""
    from app.core.database import SessionLocal
    from app.services.email_service import EmailService

    db = SessionLocal()
    try:
        svc = EmailService(db, token=token)
        log = svc.send(
            event_type=event_type,
            recipient_user_id=recipient_user_id,
            context=context,
            force=force,
        )
        if log:
            logger.info(
                "Email job done: id=%s status=%s to=%s",
                log.id, log.status, log.recipient_email,
            )
    except Exception:
        logger.exception(
            "Email job failed for user %s event %s",
            recipient_user_id, event_type,
        )
    finally:
        db.close()
