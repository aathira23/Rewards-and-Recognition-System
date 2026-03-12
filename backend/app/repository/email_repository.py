from typing import Optional, List

from sqlalchemy.orm import Session

from app.models.email_logs import EmailLog
from app.models.users import User
from app.models.system_config import SystemConfig


class EmailRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_user_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def is_email_enabled(self) -> bool:
        row = self.db.query(SystemConfig).filter(
            SystemConfig.key == "feature.email_notifications_enabled"
        ).first()
        return row is not None and row.value.lower() in ("true", "1", "yes")

    def create_log(self, **kwargs) -> EmailLog:
        log = EmailLog(**kwargs)
        self.db.add(log)
        self.db.flush()
        return log

    def get_logs(self, limit: int = 50, offset: int = 0) -> List[EmailLog]:
        return (
            self.db.query(EmailLog)
            .order_by(EmailLog.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        self.db.refresh(obj)
