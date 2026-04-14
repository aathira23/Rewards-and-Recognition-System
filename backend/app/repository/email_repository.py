from typing import List

from sqlalchemy.orm import Session

from app.models.email_logs import EmailLog
from app.utils.query_loader import QueryLoader


class EmailRepository:
    def __init__(self, db: Session):
        self.db = db
        self.q = QueryLoader().get_queries(EmailLog)

    def is_email_enabled(self) -> bool:
        row = self.db.execute(self.q.GET_FEATURE_FLAG).mappings().fetchone()
        return row is not None and row["value"].lower() in ("true", "1", "yes")

    def create_log(self, **kwargs):
        result = self.db.execute(self.q.CREATE, {**kwargs})
        self.db.flush()
        return (
            self.db.execute(self.q.GET_BY_ID, {"id": result.lastrowid})
            .mappings()
            .fetchone()
        )

    def get_logs(self, limit: int = 50, offset: int = 0) -> List[object]:
        return (
            self.db.execute(self.q.GET_RECENT, {"limit": limit, "offset": offset})
            .mappings()
            .fetchall()
        )

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        pass  # not needed with raw SQL
