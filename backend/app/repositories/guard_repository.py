from datetime import date

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.visitor import Visitor
from app.repositories.delivery_repository import DeliveryRepository
from app.repositories.vehicle_repository import VehicleRepository

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
                Visitor.status.in_(
                    [
                        "PENDING",
                        "APPROVED",
                    ]
                )
            )
            .order_by(
                Visitor.expected_time.asc()
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

    def approved_visitors(self):

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

    def approved_count(self):
        return (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.status == "APPROVED"
            )
            .scalar()
            or 0
        )


    def pending_count(self):
        return (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.status == "PENDING"
            )
            .scalar()
            or 0
        )


    def inside_count(self):
        return (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.status == "CHECKED_IN"
            )
            .scalar()
            or 0
        )

    @property
    def delivery_repository(self) -> DeliveryRepository:
        return DeliveryRepository(self.db)


    @property
    def vehicle_repository(self) -> VehicleRepository:
        return VehicleRepository(self.db)