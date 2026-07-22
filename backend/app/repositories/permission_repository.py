from sqlalchemy.orm import Session

from app.models.permission import Permission


class PermissionRepository:
    """
    Repository for Permission CRUD operations.
    """

    def __init__(self, db: Session):
        self.db = db

    def create(self, permission: Permission) -> Permission:
        self.db.add(permission)
        self.db.commit()
        self.db.refresh(permission)
        return permission

    def get_by_id(self, permission_id: int) -> Permission | None:
        return (
            self.db.query(Permission)
            .filter(Permission.id == permission_id)
            .first()
        )

    def get_by_code(self, code: str) -> Permission | None:
        return (
            self.db.query(Permission)
            .filter(Permission.code == code)
            .first()
        )

    def get_all(self) -> list[Permission]:
        return (
            self.db.query(Permission)
            .order_by(Permission.module, Permission.code)
            .all()
        )

    def get_by_module(self, module: str) -> list[Permission]:
        return (
            self.db.query(Permission)
            .filter(Permission.module == module)
            .order_by(Permission.code)
            .all()
        )