from typing import List, Callable
from fastapi import Depends, HTTPException, status
from jose import jwt, JWTError

from app.config import settings
from app.security.auth import oauth2_scheme


async def get_current_user_data(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        role: str = payload.get("role", "staff").upper()
        staff_id: str = payload.get("staff_id", "")
        staff_name: str = payload.get("staff_name", "")
        return {
            "sub": payload.get("sub"),
            "role": role,
            "staff_id": staff_id,
            "staff_name": staff_name,
        }
    except JWTError:
        raise credentials_exception


def require_role(allowed_roles: List[str]) -> Callable:
    """
    Dependency factory to enforce Role-Based Access Control (RBAC).
    Allowed roles: 'ADMIN', 'STAFF', 'VIEWER'
    """
    normalized_allowed = [r.upper() for r in allowed_roles]

    async def role_checker(current_user: dict = Depends(get_current_user_data)) -> dict:
        user_role = current_user.get("role", "VIEWER").upper()
        if user_role not in normalized_allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Required role: {', '.join(normalized_allowed)} (Your role: {user_role}).",
            )
        return current_user

    return role_checker


require_admin = require_role(["ADMIN"])
require_staff_or_admin = require_role(["ADMIN", "STAFF"])
require_any_authenticated = require_role(["ADMIN", "STAFF", "VIEWER"])
