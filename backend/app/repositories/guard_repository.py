from datetime import date

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.visitor import Visitor


class GuardRepository:

    def __init__(self, db: Session):
        self.db = db

    # -------------------------
    # Today's Visitors
    # -------------------------

    def today_expected_visitors(self):

        today = date.today()

        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "APPROVED",
                func.date(
                    Visitor.expected_time
                ) == today,
            )
            .order_by(
                Visitor.expected_time.asc()
            )
            .all()
        )

    # -------------------------
    # Today's Check-ins
    # -------------------------

    def today_checked_in_count(self):

        today = date.today()

        return (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.check_in_time.isnot(None),
                func.date(
                    Visitor.check_in_time
                ) == today,
            )
            .scalar()
        )

    # -------------------------
    # Recent Activities
    # -------------------------

    def recent_activities(self):

        visitors = (

            self.db.query(Visitor)

            .filter(

                Visitor.status.in_(

                    [

                        "APPROVED",

                        "CHECKED_IN",

                        "CHECKED_OUT",

                    ]
                )
            )

            .all()
        )

        def latest_time(visitor):

            return (

                visitor.check_out_time

                or visitor.check_in_time

                or visitor.approved_at

                or visitor.created_at

            )

        visitors.sort(

            key=latest_time,

            reverse=True,

        )

        return visitors[:20]
    # -------------------------
    # Pending Visitors
    # -------------------------

    def pending_visitors(self):

        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "PENDING"
            )
            .all()
        )

    # -------------------------
    # Visitors Inside
    # -------------------------

    def visitors_inside(self):

        return (
            self.db.query(Visitor)
            .filter(
                Visitor.status == "CHECKED_IN"
            )
            .all()
        )