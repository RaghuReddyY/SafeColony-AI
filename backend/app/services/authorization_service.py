from app.auth.role_permissions import ROLE_PERMISSIONS
from app.enums import UserRole
from app.core.logger import logger


class AuthorizationService:

    @staticmethod
    def has_permission(
        user,
        permission: str,
    ) -> bool:

        # =====================================================
        # Normalize database role
        # =====================================================

        raw_role = user.role

        if isinstance(raw_role, UserRole):
            role = raw_role

        else:
            try:
                role = UserRole(str(raw_role))

            except ValueError:

                logger.error(
                    "Invalid role '%s' found for user '%s'",
                    raw_role,
                    user.email,
                )

                return False

        # =====================================================
        # Get permissions
        # =====================================================

        permissions = ROLE_PERMISSIONS.get(
            role,
            set(),
        )

        # =====================================================
        # Permission check
        # =====================================================

        has_access = permission in permissions

        # =====================================================
        # Logging
        # =====================================================

        logger.info(
            "RBAC Check | user=%s | role=%s | "
            "permission=%s | allowed=%s",
            user.email,
            role.value,
            permission,
            has_access,
        )

        logger.info(
            "RBAC Permissions | role=%s | permissions=%s",
            role.value,
            sorted(permissions),
        )

        return has_access