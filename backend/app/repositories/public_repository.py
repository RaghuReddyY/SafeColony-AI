from sqlalchemy.orm import Session, joinedload

from app.models.organization import Organization
from app.models.property import Property
from app.models.section import Section


class PublicRepository:

    def __init__(self, db: Session):
        self.db = db

    # --------------------------------------------------
    # Organization Lookup
    # --------------------------------------------------

    def get_organization_by_code(
        self,
        organization_code: str,
    ) -> Organization | None:

        return (
            self.db.query(Organization)
            .options(
                joinedload(Organization.properties),
            )
            .filter(
                Organization.organization_code == organization_code,
                Organization.is_active.is_(True),
            )
            .first()
        )

    # --------------------------------------------------
    # Property Lookup
    # --------------------------------------------------

    def get_property(
        self,
        property_id: int,
    ) -> Property | None:

        return (
            self.db.query(Property)
            .filter(
                Property.id == property_id,
            )
            .first()
        )

    # --------------------------------------------------
    # Section Lookup
    # --------------------------------------------------

    def get_sections_by_property(
        self,
        property_id: int,
    ) -> list[Section]:

        return (
            self.db.query(Section)
            .filter(
                Section.property_id == property_id,
            )
            .order_by(Section.name.asc())
            .all()
        )