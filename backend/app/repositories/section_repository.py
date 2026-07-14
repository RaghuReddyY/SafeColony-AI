from sqlalchemy.orm import Session

from app.models.section import Section


class SectionRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, section: Section):
        self.db.add(section)
        self.db.commit()
        self.db.refresh(section)
        return section

    def get_all(self):
        return self.db.query(Section).all()

    def get_by_property(self, property_id: int):
        return (
            self.db.query(Section)
            .filter(Section.property_id == property_id)
            .all()
        )