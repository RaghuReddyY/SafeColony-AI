from datetime import date

from app.models.visitor import Visitor


class GuardDashboardRepository:

    def __init__(self, db):
        self.db = db

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