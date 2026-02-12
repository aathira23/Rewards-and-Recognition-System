"""
Departments API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.users import User
from app.utils.enums import UserRole
from app.services.department_service import DepartmentService
from app.schemas.departments import DepartmentCreate, DepartmentUpdate, DepartmentResponse
from app.utils.response import success, created, client_error

router = APIRouter()


@router.get("/", response_model=List[DepartmentResponse])
def list_departments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all departments (All authenticated users)."""
    service = DepartmentService(db)
    depts = service.list_departments()
    data = [DepartmentResponse.model_validate(d) for d in depts]
    return success(data=data, message="Departments retrieved")


@router.post("/", response_model=DepartmentResponse)
def create_department(
    dept: DepartmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new department (HR only)."""
    if current_user.role != UserRole.HR.value:
        return client_error(message="Access denied. Only HR can create departments.", status_code=403)
        
    service = DepartmentService(db)
    try:
        new_dept = service.create_department(dept)
        return created(data=DepartmentResponse.model_validate(new_dept), message="Department created successfully")
    except ValueError as e:
        return client_error(message=str(e))


@router.put("/{dept_id}", response_model=DepartmentResponse)
def update_department(
    dept_id: int,
    dept_in: DepartmentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a department (HR only)."""
    if current_user.role != UserRole.HR.value:
        return client_error(message="Access denied. Only HR can update departments.", status_code=403)
        
    service = DepartmentService(db)
    try:
        updated = service.update_department(dept_id, dept_in)
        if not updated:
            return client_error(message="Department not found", status_code=404)
        return success(data=DepartmentResponse.model_validate(updated), message="Department updated successfully")
    except ValueError as e:
        return client_error(message=str(e))


@router.delete("/{dept_id}")
def delete_department(
    dept_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a department (HR only)."""
    if current_user.role != UserRole.HR.value:
        return client_error(message="Access denied. Only HR can delete departments.", status_code=403)
        
    service = DepartmentService(db)
    # Note: In a real system, we'd check if users belong to this department before deleting.
    deleted = service.delete_department(dept_id)
    if not deleted:
        return client_error(message="Department not found", status_code=404)
    return success(message="Department deleted successfully")
