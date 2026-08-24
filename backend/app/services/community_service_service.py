from app.core.exceptions import NotFoundException
from app.models.community_service import CommunityService
from app.repositories.community_service_repository import CommunityServiceRepository


class CommunityServiceService:
    def __init__(self, repo: CommunityServiceRepository):
        self.repo = repo

    @staticmethod
    def _response(item: CommunityService):
        return {
            "id": item.id,
            "name": item.name,
            "category": item.category,
            "phone": item.phone,
            "work_description": item.work_description,
            "notes": item.notes,
            "is_active": item.is_active,
            "created_by_name": item.created_by.full_name if item.created_by else None,
            "updated_by_name": item.updated_by.full_name if item.updated_by else None,
            "created_at": item.created_at,
            "updated_at": item.updated_at,
        }

    def list(self, organization_id: int, category: str | None = None):
        return [self._response(item) for item in self.repo.get_all(organization_id, category)]

    def create(self, data, organization_id: int, user_id: int):
        item = CommunityService(
            organization_id=organization_id,
            created_by_id=user_id,
            updated_by_id=user_id,
            name=data.name.strip(),
            category=data.category.strip(),
            phone=data.phone.strip(),
            work_description=data.work_description.strip(),
            notes=data.notes.strip() if data.notes else None,
        )
        return self._response(self.repo.create(item))

    def update(self, item_id: int, data, organization_id: int, user_id: int):
        item = self.repo.get_by_id(item_id, organization_id)
        if not item:
            raise NotFoundException("Community service")

        for field in ("name", "category", "phone", "work_description", "notes", "is_active"):
            value = getattr(data, field)
            if value is not None:
                if isinstance(value, str):
                    value = value.strip()
                setattr(item, field, value)

        item.updated_by_id = user_id
        return self._response(self.repo.save(item))
