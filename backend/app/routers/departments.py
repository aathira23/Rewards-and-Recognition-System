"""
Departments API endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.utils.enums import UserRole
from app.services.department_service import DepartmentService
from app.schemas.departments import DepartmentCreate, DepartmentUpdate, DepartmentResponse
from app.utils.response import success, created, client_error
from app.utils.constants import (
    SUCCESS_DEPARTMENTS_RETRIEVED, ERROR_ONLY_HR_ADMIN_CREATE_DEPT,
    SUCCESS_DEPARTMENT_CREATED, ERROR_ONLY_HR_ADMIN_UPDATE_DEPT,
    ERROR_DEPARTMENT_NOT_FOUND, SUCCESS_DEPARTMENT_UPDATED,
    ERROR_ONLY_HR_ADMIN_DELETE_DEPT, SUCCESS_DEPARTMENT_DELETED
)

router = APIRouter()


@router.get("/", response_model=List[DepartmentResponse])
def list_departments(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all departments (All authenticated users)."""
    service = DepartmentService(db)
    depts = service.list_departments()
    data = [DepartmentResponse.model_validate(d) for d in depts]
    return success(data=data, message=SUCCESS_DEPARTMENTS_RETRIEVED)


@router.post("/", response_model=DepartmentResponse)
def create_department(
    dept: DepartmentCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new department (HR only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_CREATE_DEPT, status_code=403)

    service = DepartmentService(db)
    try:
        new_dept = service.create_department(dept)
        return created(data=DepartmentResponse.model_validate(new_dept), message=SUCCESS_DEPARTMENT_CREATED)
    except ValueError as e:
        return client_error(message=str(e))


@router.put("/{dept_id}", response_model=DepartmentResponse)
def update_department(
    dept_id: int,
    dept_in: DepartmentUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a department (HR only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_UPDATE_DEPT, status_code=403)

    service = DepartmentService(db)
    try:
        updated = service.update_department(dept_id, dept_in)
        if not updated:
            return client_error(message=ERROR_DEPARTMENT_NOT_FOUND, status_code=404)
        return success(data=DepartmentResponse.model_validate(updated), message=SUCCESS_DEPARTMENT_UPDATED)
    except ValueError as e:
        return client_error(message=str(e))


@router.delete("/{dept_id}")
def delete_department(
    dept_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a department (HR only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_DELETE_DEPT, status_code=403)

    service = DepartmentService(db)
    # Note: In a real system, we'd check if users belong to this department before deleting.
    deleted = service.delete_department(dept_id)
    if not deleted:
        return client_error(message=ERROR_DEPARTMENT_NOT_FOUND, status_code=404)
    return success(message=SUCCESS_DEPARTMENT_DELETED)
