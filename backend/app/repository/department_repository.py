from typing import Optional, List

from sqlalchemy.orm import Session

from app.models.departments import Department


class DepartmentRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> List[Department]:
        return self.db.query(Department).all()

    def get_by_id(self, dept_id: int) -> Optional[Department]:
        return self.db.query(Department).filter(Department.id == dept_id).first()

    def get_by_name(self, name: str) -> Optional[Department]:
        return self.db.query(Department).filter(Department.name == name).first()

    def create(self, name: str) -> Department:
        dept = Department(name=name)
        self.db.add(dept)
        self.db.commit()
        self.db.refresh(dept)
        return dept

    def update(self, dept: Department) -> Department:
        self.db.add(dept)
        self.db.commit()
        self.db.refresh(dept)
        return dept

    def delete(self, dept: Department) -> None:
        self.db.delete(dept)
        self.db.commit()
