"""
Department service - Business logic for department management.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.departments import Department
from app.schemas.departments import DepartmentCreate, DepartmentUpdate


class DepartmentService:
    """Service for managing departments."""

    def __init__(self, db: Session):
        self.db = db

    def list_departments(self) -> List[Department]:
        """List all departments."""
        return self.db.query(Department).all()

    def get_department_by_id(self, dept_id: int) -> Optional[Department]:
        """Get a department by ID."""
        return self.db.query(Department).filter(Department.id == dept_id).first()

    def get_department_by_name(self, name: str) -> Optional[Department]:
        """Get a department by name."""
        return self.db.query(Department).filter(Department.name == name).first()

    def create_department(self, dept_in: DepartmentCreate) -> Department:
        """Create a new department."""
        existing = self.get_department_by_name(dept_in.name)
        if existing:
            raise ValueError(f"Department with name '{dept_in.name}' already exists.")

        dept = Department(name=dept_in.name)
        self.db.add(dept)
        self.db.commit()
        self.db.refresh(dept)
        return dept

    def update_department(self, dept_id: int, dept_in: DepartmentUpdate) -> Optional[Department]:
        """Update a department."""
        dept = self.get_department_by_id(dept_id)
        if not dept:
            return None

        if dept_in.name is not None:
            # Check if new name already exists for another department
            existing = self.get_department_by_name(dept_in.name)
            if existing and existing.id != dept_id:
                raise ValueError(f"Department with name '{dept_in.name}' already exists.")
            dept.name = dept_in.name

        self.db.add(dept)
        self.db.commit()
        self.db.refresh(dept)
        return dept

    def delete_department(self, dept_id: int) -> bool:
        """Delete a department."""
        dept = self.get_department_by_id(dept_id)
        if not dept:
            return False

        self.db.delete(dept)
        self.db.commit()
        return True
