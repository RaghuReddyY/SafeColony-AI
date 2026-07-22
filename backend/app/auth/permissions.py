from collections.abc import Callable

from fastapi import Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.models.user import User
from app.services.authorization_service import AuthorizationService


def require_permission(permission: str) -> Callable:

    def permission_checker(
        current_user: User = Depends(get_current_user),
    ) -> User:

        if not AuthorizationService.has_permission(
            current_user,
            permission,
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action.",
            )

        return current_user

    return permission_checker