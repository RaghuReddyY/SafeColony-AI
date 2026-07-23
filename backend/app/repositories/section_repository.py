from sqlalchemy.orm import Session

from app.models.section import Section


class SectionRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        section: Section,
    ) -> Section:

        self.db.add(section)
        self.db.commit()
        self.db.refresh(section)

        return section


    def get_all(self) -> list[Section]:

        return (
            self.db.query(Section)
            .order_by(Section.name)
            .all()
        )


    def get_by_id(
        self,
        section_id: int,
    ) -> Section | None:

        return (
            self.db.query(Section)
            .filter(
                Section.id == section_id
            )
            .first()
        )


    def get_by_property(
        self,
        property_id: int,
    ) -> list[Section]:

        return (
            self.db.query(Section)
            .filter(
                Section.property_id == property_id
            )
            .order_by(Section.name)
            .all()
        )


    def exists_by_name(
        self,
        property_id: int,
        name: str,
    ) -> bool:

        return (
            self.db.query(Section)
            .filter(
                Section.property_id == property_id,
                Section.name.ilike(name),
            )
            .first()
            is not None
        )


    def update(
        self,
        section: Section,
    ) -> Section:

        self.db.commit()
        self.db.refresh(section)

        return section


    def delete(
        self,
        section: Section,
    ):

        self.db.delete(section)
        self.db.commit()

    def get_by_id_and_organization(
        self,
        section_id: int,
        organization_id: int,
    ) -> Section | None:

        from app.models.property import Property

        return (
            self.db.query(Section)
            .join(Property)
            .filter(
                Section.id == section_id,
                Property.organization_id == organization_id,
            )
            .first()
        )