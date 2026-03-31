"""
Department service - Business logic for department management.

Uses a module-level TTLCache (1 h) for the department list and individual
lookups so the DB is not hit on every picker/dropdown render.
"""
import logging
from typing import List, Optional
from sqlalchemy.orm import Session
from cachetools import TTLCache

from app.schemas.departments import DepartmentCreate, DepartmentUpdate
from app.repository.department_repository import DepartmentRepository

logger = logging.getLogger(__name__)

# 1 h TTL, generous size for dept lists + individual lookups
_dept_cache: TTLCache = TTLCache(maxsize=500, ttl=60 * 60)


class DepartmentService:
    """Service for managing departments."""

    def __init__(self, db: Session):
        self.db = db
        self.repository = DepartmentRepository(db)

    def list_departments(self):
        """List all departments (served from 1 h cache)."""
        cache_key = "all"
        if cache_key in _dept_cache:
            return _dept_cache[cache_key]
        result = self.repository.get_all()
        _dept_cache[cache_key] = result
        return result

    def get_department_by_id(self, dept_id: int):
        """Get a department by ID (served from 1 h cache)."""
        cache_key = f"id:{dept_id}"
        if cache_key in _dept_cache:
            return _dept_cache[cache_key]
        dept = self.repository.get_by_id(dept_id)
        if dept:
            _dept_cache[cache_key] = dept
        return dept

    def get_department_by_name(self, name: str):
        """Get a department by name."""
        return self.repository.get_by_name(name)

    def create_department(self, dept_in: DepartmentCreate):
        """Create a new department."""
        existing = self.repository.get_by_name(dept_in.name)
        if existing:
            raise ValueError(f"Department with name '{dept_in.name}' already exists.")
        result = self.repository.create(dept_in.name)
        _dept_cache.clear()
        return result

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

        result = self.repository.update(dept)
        _dept_cache.clear()
        return result

    def delete_department(self, dept_id: int) -> bool:
        """Delete a department."""
        dept = self.repository.get_by_id(dept_id)
        if not dept:
            return False
        self.repository.delete(dept)
        _dept_cache.clear()
        return True
