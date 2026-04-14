from typing import Optional

from sqlalchemy.orm import Session

from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_ledger import PointsLedger
from app.utils.enums import WalletType
from app.utils.query_loader import QueryLoader


class WalletsRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.wallet_q = loader.get_queries(Wallet)
        self.funding_q = loader.get_queries(WalletFunding)
        self.ledger_q = loader.get_queries(PointsLedger)

    def get_wallet(self, user_id: int, wallet_type: str):
        return (
            self.db.execute(
                self.wallet_q.GET_BY_USER_AND_TYPE,
                {"user_id": user_id, "wallet_type": wallet_type},
            )
            .mappings()
            .fetchone()
        )

    def get_or_create_wallet(self, user_id: int, wallet_type: WalletType):
        wallet = self.get_wallet(user_id, wallet_type.value)
        if not wallet:
            result = self.db.execute(
                self.wallet_q.CREATE,
                {"user_id": user_id, "wallet_type": wallet_type.value, "balance": 0},
            )
            self.db.commit()
            wallet = (
                self.db.execute(
                    self.wallet_q.GET_BY_ID, {"id": result.lastrowid}
                )
                .mappings()
                .fetchone()
            )
        return wallet

    def create_funding(self, wallet_id: int, funded_by: int, points: int):
        result = self.db.execute(
            self.funding_q.CREATE,
            {"manager_wallet_id": wallet_id, "funded_by": funded_by, "points": points},
        )
        return (
            self.db.execute(
                self.funding_q.GET_BY_ID, {"id": result.lastrowid}
            )
            .mappings()
            .fetchone()
        )

    def add_ledger_entry(
        self,
        points: int,
        transaction_type: str,
        reference_type: str,
        reference_id: int,
        *,
        source_wallet_id: Optional[int] = None,
        target_wallet_id: Optional[int] = None,
    ):
        result = self.db.execute(
            self.ledger_q.CREATE,
            {
                "source_wallet_id": source_wallet_id,
                "target_wallet_id": target_wallet_id,
                "points": points,
                "transaction_type": transaction_type,
                "reference_type": reference_type,
                "reference_id": reference_id,
            },
        )
        return (
            self.db.execute(
                self.ledger_q.GET_BY_ID, {"id": result.lastrowid}
            )
            .mappings()
            .fetchone()
        )

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        pass  # not needed with raw SQL — rows are re-fetched after writes
