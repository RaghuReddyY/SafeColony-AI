from sqlalchemy.orm import Session

from app.models.property import Property


class PropertyRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, property: Property) -> Property:
        self.db.add(property)
        self.db.commit()
        self.db.refresh(property)
        return property

    def get_all(self) -> list[Property]:
        return (
            self.db.query(Property)
            .order_by(Property.name)
            .all()
        )

    def get(self, property_id: int) -> Property | None:
        return (
            self.db.query(Property)
            .filter(Property.id == property_id)
            .first()
        )

    def get_by_organization(
        self,
        organization_id: int,
    ) -> list[Property]:
        return (
            self.db.query(Property)
            .filter(Property.organization_id == organization_id)
            .order_by(Property.name)
            .all()
        )

    def exists_by_name(
        self,
        organization_id: int,
        name: str,
    ) -> bool:
        return (
            self.db.query(Property)
            .filter(
                Property.organization_id == organization_id,
                Property.name.ilike(name),
            )
            .first()
            is not None
        )

    def update(self, property: Property) -> Property:
        self.db.commit()
        self.db.refresh(property)
        return property

    def delete(self, property: Property) -> None:
        self.db.delete(property)
        self.db.commit()