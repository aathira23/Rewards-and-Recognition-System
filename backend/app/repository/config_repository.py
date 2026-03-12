from typing import Optional, List

from sqlalchemy.orm import Session

from app.models.system_config import SystemConfig


class ConfigRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_key(self, key: str) -> Optional[SystemConfig]:
        return self.db.query(SystemConfig).filter(SystemConfig.key == key).first()

    def get_all(self) -> List[SystemConfig]:
        return self.db.query(SystemConfig).all()

    def upsert(self, key: str, value: str, description: Optional[str] = None) -> SystemConfig:
        config = self.get_by_key(key)
        if config:
            config.value = value
            if description:
                config.description = description
        else:
            config = SystemConfig(key=key, value=value, description=description)
            self.db.add(config)
        self.db.commit()
        return config
