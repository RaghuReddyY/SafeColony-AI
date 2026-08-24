from sqlalchemy.orm import Session

from app.models.community_service import CommunityService


class CommunityServiceRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, item: CommunityService):
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def save(self, item: CommunityService):
        self.db.commit()
        self.db.refresh(item)
        return item

    def get_by_id(self, item_id: int, organization_id: int):
        return (
            self.db.query(CommunityService)
            .filter(
                CommunityService.id == item_id,
                CommunityService.organization_id == organization_id,
            )
            .first()
        )

    def get_all(self, organization_id: int, category: str | None = None):
        query = (
            self.db.query(CommunityService)
            .filter(
                CommunityService.organization_id == organization_id,
                CommunityService.is_active.is_(True),
            )
        )
        if category:
            query = query.filter(CommunityService.category.ilike(category))
        return query.order_by(CommunityService.category.asc(), CommunityService.name.asc()).all()
