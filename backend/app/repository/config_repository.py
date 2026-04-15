from typing import Optional, List

from sqlalchemy.orm import Session

from app.models.system_config import SystemConfig
from app.utils.query_loader import QueryLoader


class ConfigRepository:
    def __init__(self, db: Session):
        self.db = db
        self.q = QueryLoader().get_queries(SystemConfig)

    def get_by_key(self, key: str) -> Optional[object]:
        return (
            self.db.execute(self.q.GET_BY_KEY, {"key": key}).mappings().fetchone()
        )

    def get_all(self) -> List[object]:
        return self.db.execute(self.q.GET_ALL).mappings().fetchall()

    def upsert(self, key: str, value: str, description: Optional[str] = None):
        self.db.execute(
            self.q.UPSERT,
            {"key": key, "value": value, "description": description},
        )
        self.db.commit()
        return self.get_by_key(key)
