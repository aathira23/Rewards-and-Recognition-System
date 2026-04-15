from typing import Optional, Dict, Any


def serialize_user_context(ctx) -> Dict[str, Any]:
    """
    Serialize a UserContext (user_service mode) to the same response shape as serialize_user.
    Used by GET /profile/me.
    """
    return {
        "id": ctx.id,
        "name": ctx.name,
        "role": ctx.role,
        "email": getattr(ctx, "email", None),
        "department_id": getattr(ctx, "department_id", None),
        "department_name": getattr(ctx, "department_name", None),
        "manager_id": None,
        "manager_name": None,
        "emp_id": getattr(ctx, "emp_id", None),
        "designation": getattr(ctx, "designation", None),
        "img_path": getattr(ctx, "img_path", None),
        "org_id": getattr(ctx, "org_id", None),
        "dob": getattr(ctx, "dob", None),
        "date_of_joining": None,
        "created_at": None,
    }


def serialize_user_profile(profile) -> Dict[str, Any]:
    """
    Serialize a UserProfile (Cache 2) to user list item format.
    Used by GET /profile/.
    """
    return {
        "id": profile.id,
        "name": profile.name,
        "role": getattr(profile, "role", None),
        "email": getattr(profile, "email", None),
        "department_id": getattr(profile, "department_id", None),
        "department_name": getattr(profile, "department_name", None),
        "manager_id": None,
        "manager_name": None,
        "emp_id": getattr(profile, "emp_id", None),
        "designation": getattr(profile, "designation", None),
        "img_path": getattr(profile, "img_path", None),
        "org_id": getattr(profile, "org_id", None),
        "dob": getattr(profile, "dob", None),
        "date_of_joining": getattr(profile, "date_of_joining", None),
        "is_active": getattr(profile, "is_active", None),
    }
