from app.models.permission import Permission
from app.repositories.permission_repository import PermissionRepository


class PermissionService:
    """
    Business logic for Permission management.
    """

    def __init__(self, repository: PermissionRepository):
        self.repository = repository

    def create_permission(
        self,
        code: str,
        module: str,
        description: str,
    ) -> Permission:

        existing = self.repository.get_by_code(code)

        if existing:
            raise ValueError(
                f"Permission '{code}' already exists."
            )

        permission = Permission(
            code=code,
            module=module,
            description=description,
        )

        return self.repository.create(permission)

    def get_permissions(self) -> list[Permission]:
        return self.repository.get_all()

    def get_module_permissions(
        self,
        module: str,
    ) -> list[Permission]:
        return self.repository.get_by_module(module)