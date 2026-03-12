from typing import Optional, List, Tuple

from sqlalchemy.orm import Session

from app.models.users import User
from app.schemas.users import UserCreate, UserUpdate
from app.core.security import get_password_hash


class UsersRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def count(self) -> int:
        return self.db.query(User).count()

    def list_paginated(self, skip: int, limit: int) -> Tuple[int, List[User]]:
        total = self.db.query(User).count()
        users = self.db.query(User).offset(skip).limit(limit).all()
        return total, users

    def create(self, user_in: UserCreate) -> User:
        hashed = get_password_hash(user_in.password)
        user = User(
            name=user_in.name,
            email=user_in.email,
            password=hashed,
            role=user_in.role,
            department_id=user_in.department_id if user_in.department_id != 0 else None,
            manager_id=user_in.manager_id if user_in.manager_id != 0 else None,
            date_of_joining=user_in.date_of_joining,
            birth_date=user_in.birth_date,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update(self, user: User, user_in: UserUpdate) -> User:
        for field, value in user_in.__dict__.items():
            if field in ["department_id", "manager_id"] and value == 0:
                value = None
            if value is not None:
                setattr(user, field, value)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_role(self, role: str) -> List[User]:
        return self.db.query(User).filter(User.role == role).all()

    def get_by_roles(self, roles: List[str]) -> List[User]:
        return self.db.query(User).filter(User.role.in_(roles)).all()

    def get_by_department(self, department_id: int) -> List[User]:
        return self.db.query(User).filter(User.department_id == department_id).all()

    def get_ids_by_manager(self, manager_id: int) -> List[int]:
        rows = self.db.query(User.id).filter(User.manager_id == manager_id).all()
        return [r.id for r in rows]

    def get_ids_by_department(self, department_id: int) -> List[int]:
        rows = self.db.query(User.id).filter(User.department_id == department_id).all()
        return [r.id for r in rows]

    def get_managers_in_department(self, department_id: int) -> List[User]:
        return self.db.query(User).filter(
            User.department_id == department_id,
            User.manager_id != None,
        ).all()
