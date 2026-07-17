from datetime import date

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
            .filter(
                Visitor.resident_id == resident_id
            )
            .order_by(
                Visitor.created_at.desc()
            )
            .all()
        )

    def save(self, visitor: Visitor):
        self.db.commit()
        self.db.refresh(visitor)
        return visitor

    def get_by_qr_token(self, qr_token: str):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.qr_token == qr_token
            )
            .first()
        )

    # ----------------------------------------
    # Guard Dashboard
    # ----------------------------------------

    def get_expected_visitors(self):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "APPROVED"
            )
            .order_by(
                Visitor.expected_time.asc()
            )
            .all()
        )

    def get_checked_in_today(self):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "CHECKED_IN"
            )
            .count()
        )