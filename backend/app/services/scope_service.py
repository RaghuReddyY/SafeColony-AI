from app.enums import UserRole
from app.models.user_block_scope import UserBlockScope
from app.models.resident import Resident
from app.models.unit import Unit


class ScopeService:
    """Centralized authorization scope for block/community administrators."""

    COMMUNITY_ROLES = {
        UserRole.SYSTEM_ADMIN.value,
        UserRole.ORGANIZATION_ADMIN.value,
        UserRole.COMMUNITY_FINANCE_ADMIN.value,
    }

    @classmethod
    def is_community_wide(cls, user) -> bool:
        return user.role in cls.COMMUNITY_ROLES

    @classmethod
    def block_ids(cls, db, user) -> list[int]:
        if cls.is_community_wide(user):
            return []
        rows = (
            db.query(UserBlockScope.section_id)
            .filter(UserBlockScope.user_id == user.id)
            .all()
        )
        return [row[0] for row in rows]

    @classmethod
    def can_access_section(cls, db, user, section_id: int | None) -> bool:
        if section_id is None:
            return cls.is_community_wide(user)
        if cls.is_community_wide(user):
            return True
        return section_id in cls.block_ids(db, user)

    @classmethod
    def resident_section_id(cls, resident: Resident) -> int | None:
        return resident.unit.section_id if resident and resident.unit else None

    @classmethod
    def unit_ids(cls, db, user) -> list[int]:
        sections = cls.block_ids(db, user)
        if not sections:
            return []
        rows = db.query(Unit.id).filter(Unit.section_id.in_(sections)).all()
        return [row[0] for row in rows]
