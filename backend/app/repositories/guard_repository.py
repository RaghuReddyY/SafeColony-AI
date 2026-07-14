from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.visitor import Visitor


class GuardRepository:

    def __init__(self, db: Session):
        self.db = db

    def count_by_status(self, status):

        return (
            self.db.query(func.count(Visitor.id))
            .filter(Visitor.status == status)
            .scalar()
        )

    def get_pending(self):

        return (
            self.db.query(Visitor)
            .filter(Visitor.status == "PENDING")
            .all()
        )

    def get_inside(self):

        return (
            self.db.query(Visitor)
            .filter(Visitor.status == "CHECKED_IN")
            .all()
        )