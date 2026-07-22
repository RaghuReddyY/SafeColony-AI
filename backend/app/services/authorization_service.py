from app.auth.role_permissions import ROLE_PERMISSIONS
from app.enums import UserRole
from app.core.logger import logger


class AuthorizationService:

    @staticmethod
    def has_permission(user, permission: str) -> bool:

        # Normalize role
        if isinstance(user.role, str):
            try:
                role = UserRole(user.role)
            except ValueError:
                logger.error(
                    "Invalid role '%s' found for user '%s'",
                    user.role,
                    user.email,
                )
                return False
        else:
            role = user.role

        permissions = ROLE_PERMISSIONS.get(role, set())
        has_access = permission in permissions

        logger.info(
            "RBAC Check | user=%s | role=%s | permission=%s | allowed=%s",
            user.email,
            role.value,
            permission,
            has_access,
        )

        if logger.isEnabledFor(10):  # DEBUG
            logger.debug(
                "Permissions for role %s: %s",
                role.value,
                sorted(permissions),
            )

        return has_access