from sqlalchemy.orm import Session

from app.models.visitor import Visitor


class VisitorRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, visitor: Visitor):
        self.db.add(visitor)
        self.db.commit()
        self.db.refresh(visitor)
        return visitor

    def get_all(self):
        return self.db.query(Visitor).all()

    def get_by_id(self, visitor_id: int):
        return (
            self.db.query(Visitor)
            .filter(Visitor.id == visitor_id)
            .first()
        )

    def get_by_resident(self, resident_id: int):
        return (
            self.db.query(Visitor)
            .filter(Visitor.resident_id == resident_id)
            .all()
        )

    def save(self, visitor: Visitor):
        self.db.commit()
        self.db.refresh(visitor)
        return visitor