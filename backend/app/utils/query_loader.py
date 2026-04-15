"""
Generic QueryLoader — maps model classes to their DB-specific query class.

Follows the same Styria service pattern used in award-service / feed-service.
Switch DB type via the DB_TYPE environment variable (mysql | postgresql | mssql).

Usage::

    from app.utils.query_loader import QueryLoader
    from app.models.wallets import Wallet

    loader  = QueryLoader()                     # uses settings.DB_TYPE by default
    queries = loader.get_queries(Wallet)        # returns WalletQueries
    row     = session.execute(queries.GET_BY_ID, {"id": 1}).mappings().fetchone()

Only MySQL query classes are implemented today.
The postgresql and mssql slots are left ready for future additions.
"""
from __future__ import annotations

from typing import Any

from app.core.config import settings

# Model imports (lazy to avoid circular issues at module level)
from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_ledger import PointsLedger
from app.models.points_batches import PointsBatch
from app.models.points_policy import PointsPolicy
from app.models.points_conversion import PointsConversion
from app.models.rewards import Reward
from app.models.redemptions import Redemption
from app.models.badges import Badge
from app.models.ecards import ECard
from app.models.awards import Award
from app.models.award_types import AwardType
from app.models.award_approvals import AwardApproval
from app.models.notifications import Notification
from app.models.celebrations import Celebration
from app.models.recognition_feed import RecognitionFeed
from app.models.system_config import SystemConfig
from app.models.email_logs import EmailLog

# MySQL query classes
from app.utils.mysql_queries import (
    WalletQueries,
    WalletFundingQueries,
    PointsLedgerQueries,
    PointsBatchQueries,
    PointsPolicyQueries,
    PointsConversionQueries,
    RewardQueries,
    RedemptionQueries,
    BadgeQueries,
    ECardQueries,
    AwardTypeQueries,
    AwardQueries,
    AwardApprovalQueries,
    NotificationQueries,
    CelebrationQueries,
    RecognitionFeedQueries,
    SystemConfigQueries,
    EmailLogQueries,
)


class QueryLoader:
    """
    Returns the correct SQL query class for a given model and the configured DB_TYPE.

    Args:
        db_type: Override for settings.DB_TYPE.  Defaults to the value in settings.
    """

    def __init__(self, db_type: str | None = None):
        self.db_type = (db_type or settings.DB_TYPE).lower()

        self._registry: dict[str, dict[Any, Any]] = {
            "mysql": {
                Wallet:          WalletQueries,
                WalletFunding:   WalletFundingQueries,
                PointsLedger:    PointsLedgerQueries,
                PointsBatch:     PointsBatchQueries,
                PointsPolicy:    PointsPolicyQueries,
                PointsConversion: PointsConversionQueries,
                Reward:          RewardQueries,
                Redemption:      RedemptionQueries,
                Badge:           BadgeQueries,
                ECard:           ECardQueries,
                AwardType:       AwardTypeQueries,
                Award:           AwardQueries,
                AwardApproval:   AwardApprovalQueries,
                Notification:    NotificationQueries,
                Celebration:     CelebrationQueries,
                RecognitionFeed: RecognitionFeedQueries,
                SystemConfig:    SystemConfigQueries,
                EmailLog:        EmailLogQueries,
            },
            # Placeholder — add PostgreSQL / MSSQL raw-SQL classes when needed.
            "postgresql": {},
            "mssql": {},
        }

    def get_queries(self, entity: Any) -> Any:
        """
        Return the query class for *entity* under the active DB_TYPE.

        Raises:
            ValueError: if DB_TYPE is unknown or entity has no registered queries.
        """
        if self.db_type not in self._registry:
            raise ValueError(
                f"Unknown DB_TYPE '{self.db_type}'. "
                f"Supported: {list(self._registry.keys())}"
            )
        db_map = self._registry[self.db_type]
        if entity not in db_map:
            # For postgresql/mssql with empty maps, fall back gracefully so
            # repositories can still use ORM queries via SQLAlchemy until
            # those query classes are written.
            raise ValueError(
                f"No raw-SQL queries registered for entity '{entity.__name__}' "
                f"under DB_TYPE='{self.db_type}'.  "
                f"Add the query class to QueryLoader._registry or use ORM directly."
            )
        return db_map[entity]
