from sqlalchemy.orm import Session

from app.models.section import Section


class SectionRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, section: Section) -> Section:
        self.db.add(section)
        self.db.commit()
        self.db.refresh(section)
        return section

    def get_all(self) -> list[Section]:
        return self.db.query(Section).all()

    def get_by_id(self, section_id: int) -> Section | None:
        return (
            self.db.query(Section)
            .filter(Section.id == section_id)
            .first()
        )

    def get_by_property(self, property_id: int) -> list[Section]:
        return (
            self.db.query(Section)
            .filter(Section.property_id == property_id)
            .all()
        )

    def get_by_name(
        self,
        property_id: int,
        name: str,
    ) -> Section | None:
        return (
            self.db.query(Section)
            .filter(
                Section.property_id == property_id,
                Section.name == name,
            )
            .first()
        )