from datetime import date, datetime

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.visitor import Visitor


class VisitorRepository:

    def __init__(self, db: Session):
        self.db = db

    # --------------------------------------------------
    # CRUD
    # --------------------------------------------------

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

    # --------------------------------------------------
    # QR Scanner
    # --------------------------------------------------

    def get_by_qr_token(self, qr_token: str):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.qr_token == qr_token
            )
            .first()
        )

    def check_in(self, visitor: Visitor):
        visitor.status = "CHECKED_IN"
        visitor.check_in_time = datetime.utcnow()

        self.db.commit()
        self.db.refresh(visitor)

        return visitor

    def check_out(self, visitor: Visitor):
        visitor.status = "CHECKED_OUT"
        visitor.check_out_time = datetime.utcnow()

        self.db.commit()
        self.db.refresh(visitor)

        return visitor

    # --------------------------------------------------
    # Dashboard
    # --------------------------------------------------

    def get_expected_visitors(self):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "APPROVED"
            )
            .order_by(
                Visitor.expected_time.asc().nullslast(),
                Visitor.created_at.desc()
            )
            .all()
        )

    def get_expected_visitor_count(self):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "APPROVED"
            )
            .count()
        )

    def get_currently_inside_count(self):
        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "CHECKED_IN"
            )
            .count()
        )

    def get_checked_in_today_count(self):
        today = date.today()

        return (
            self.db.query(Visitor)
            .filter(
                Visitor.check_in_time.is_not(None),
                func.date(Visitor.check_in_time) == today
            )
            .count()
        )

    def get_checked_out_today_count(self):
        today = date.today()

        return (
            self.db.query(Visitor)
            .filter(
                Visitor.check_out_time.is_not(None),
                func.date(Visitor.check_out_time) == today
            )
            .count()
        )