"""
Department service - Business logic for department management.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from app.schemas.departments import DepartmentCreate, DepartmentUpdate
from app.repository.department_repository import DepartmentRepository


class DepartmentService:
    """Service for managing departments."""

    def __init__(self, db: Session):
        self.db = db
        self.repository = DepartmentRepository(db)

    def list_departments(self):
        """List all departments."""
        return self.repository.get_all()

    def get_department_by_id(self, dept_id: int):
        """Get a department by ID."""
        return self.repository.get_by_id(dept_id)

    def get_department_by_name(self, name: str):
        """Get a department by name."""
        return self.repository.get_by_name(name)

    def create_department(self, dept_in: DepartmentCreate):
        """Create a new department."""
        existing = self.repository.get_by_name(dept_in.name)
        if existing:
            raise ValueError(f"Department with name '{dept_in.name}' already exists.")
        return self.repository.create(dept_in.name)

    def update_department(self, dept_id: int, dept_in: DepartmentUpdate):
        """Update a department."""
        dept = self.repository.get_by_id(dept_id)
        if not dept:
            return None

        if dept_in.name is not None:
            existing = self.repository.get_by_name(dept_in.name)
            if existing and existing.id != dept_id:
                raise ValueError(f"Department with name '{dept_in.name}' already exists.")
            dept.name = dept_in.name

        return self.repository.update(dept)

    def delete_department(self, dept_id: int) -> bool:
        """Delete a department."""
        dept = self.repository.get_by_id(dept_id)
        if not dept:
            return False
        self.repository.delete(dept)
        return True
