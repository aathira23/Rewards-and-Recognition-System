"""
init_db.py – Creates all R&R tables in the target database.

Replaces Alembic migrations for MySQL / MSSQL deployments.
Safe to run multiple times — skips tables that already exist.

Run once after pointing DB_TYPE to the new database:
    python -m app.utils.init_db

Or call create_all_tables() from your FastAPI lifespan hook.
"""
from __future__ import annotations

import logging

from sqlalchemy import inspect

from app.core.database import Base, engine

# Import every model so SQLAlchemy's metadata knows about all tables.
from app.models.wallets import Wallet                    # noqa: F401
from app.models.wallet_funding import WalletFunding      # noqa: F401
from app.models.points_ledger import PointsLedger        # noqa: F401
from app.models.points_batches import PointsBatch        # noqa: F401
from app.models.points_policy import PointsPolicy        # noqa: F401
from app.models.points_conversion import PointsConversion  # noqa: F401
from app.models.rewards import Reward                    # noqa: F401
from app.models.redemptions import Redemption            # noqa: F401
from app.models.badges import Badge                      # noqa: F401
from app.models.ecards import ECard                      # noqa: F401
from app.models.award_types import AwardType             # noqa: F401
from app.models.awards import Award                      # noqa: F401
from app.models.award_approvals import AwardApproval     # noqa: F401
from app.models.notifications import Notification        # noqa: F401
from app.models.celebrations import Celebration          # noqa: F401
from app.models.recognition_feed import RecognitionFeed  # noqa: F401
from app.models.system_config import SystemConfig        # noqa: F401
from app.models.email_logs import EmailLog               # noqa: F401

logger = logging.getLogger(__name__)


def create_all_tables() -> None:
    """
    Create all tables that don't already exist in the target database.
    Mirrors the Styria init_db pattern used in award-service and feed-service.
    """
    inspector = inspect(engine)
    existing = set(inspector.get_table_names())

    models = [
        (Wallet,          "wallets"),
        (WalletFunding,   "wallet_funding"),
        (PointsLedger,    "points_ledger"),
        (PointsBatch,     "points_batches"),
        (PointsPolicy,    "points_policy"),
        (PointsConversion, "points_conversion"),
        (Reward,          "rewards"),
        (Redemption,      "redemptions"),
        (Badge,           "badges"),
        (ECard,           "ecards"),
        (AwardType,       "award_types"),
        (Award,           "awards"),
        (AwardApproval,   "award_approvals"),
        (Notification,    "notifications"),
        (Celebration,     "celebrations"),
        (RecognitionFeed, "recognition_feed"),
        (SystemConfig,    "system_config"),
        (EmailLog,        "email_logs"),
    ]

    for model, table_name in models:
        if table_name not in existing:
            model.metadata.create_all(bind=engine, tables=[model.__table__])
            logger.info("✅  Table '%s' created.", table_name)
            print(f"✅  Table '{table_name}' created.")
        else:
            logger.info("⚠️   Table '%s' already exists — skipped.", table_name)
            print(f"⚠️   Table '{table_name}' already exists — skipped.")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    create_all_tables()
