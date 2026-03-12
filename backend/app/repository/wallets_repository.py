from typing import Optional, List

from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_ledger import PointsLedger
from app.models.users import User
from app.utils.enums import WalletType, TransactionType


class WalletsRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_wallet(self, user_id: int, wallet_type: str) -> Optional[Wallet]:
        return self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == wallet_type,
        ).first()

    def get_or_create_wallet(self, user_id: int, wallet_type: WalletType) -> Wallet:
        wallet = self.get_wallet(user_id, wallet_type.value)
        if not wallet:
            wallet = Wallet(user_id=user_id, wallet_type=wallet_type.value, balance=0)
            self.db.add(wallet)
            self.db.commit()
            self.db.refresh(wallet)
        return wallet

    def create_funding(self, wallet_id: int, funded_by: int, points: int) -> WalletFunding:
        funding = WalletFunding(
            manager_wallet_id=wallet_id,
            funded_by=funded_by,
            points=points,
        )
        self.db.add(funding)
        return funding

    def add_ledger_entry(
        self,
        points: int,
        transaction_type: str,
        reference_type: str,
        reference_id: int,
        *,
        source_wallet_id: Optional[int] = None,
        target_wallet_id: Optional[int] = None,
    ) -> PointsLedger:
        ledger = PointsLedger(
            source_wallet_id=source_wallet_id,
            target_wallet_id=target_wallet_id,
            points=points,
            transaction_type=transaction_type,
            reference_type=reference_type,
            reference_id=reference_id,
        )
        self.db.add(ledger)
        return ledger

    def get_user_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def get_users_by_role_and_department(
        self,
        department_id: Optional[int] = None,
        user_ids: Optional[List[int]] = None,
        role_filter: Optional[str] = None,
        default_roles: Optional[List[str]] = None,
    ) -> List[User]:
        query = self.db.query(User)
        if user_ids:
            query = query.filter(User.id.in_(user_ids))
        elif department_id:
            query = query.filter(User.department_id == department_id)
            if not role_filter and default_roles:
                query = query.filter(User.role.in_(default_roles))
        if role_filter:
            query = query.filter(User.role == role_filter)
        return query.all()

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        self.db.refresh(obj)
