from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.delivery import Delivery


class DeliveryRepository:

    def __init__(self, db: Session):
        self.db = db

    # -------------------------------------------------
    # Create
    # -------------------------------------------------

    def create(self, delivery: Delivery):

        self.db.add(delivery)
        self.db.commit()
        self.db.refresh(delivery)

        return delivery

    # -------------------------------------------------
    # Read
    # -------------------------------------------------

    def get_all(self):

        return (
            self.db.query(Delivery)
            .order_by(
                Delivery.created_at.desc()
            )
            .all()
        )

    def get_by_id(self, delivery_id: int):

        return (
            self.db.query(Delivery)
            .filter(
                Delivery.id == delivery_id
            )
            .first()
        )

    def get_by_resident(
        self,
        resident_id: int,
    ):

        return (
            self.db.query(Delivery)
            .filter(
                Delivery.resident_id == resident_id
            )
            .order_by(
                Delivery.created_at.desc()
            )
            .all()
        )

    # -------------------------------------------------
    # Dashboard
    # -------------------------------------------------

    def pending_deliveries(self):

        return (
            self.db.query(Delivery)
            .filter(
                Delivery.status.in_(
                    [
                        "ARRIVED",
                        "NOTIFIED",
                    ]
                )
            )
            .order_by(
                Delivery.created_at.desc()
            )
            .all()
        )

    def pending_delivery_count(self):

        return (
            self.db.query(
                func.count(Delivery.id)
            )
            .filter(
                Delivery.status.in_(
                    [
                        "ARRIVED",
                        "NOTIFIED",
                    ]
                )
            )
            .scalar()
        )

    def collected_deliveries(self):

        return (
            self.db.query(Delivery)
            .filter(
                Delivery.status == "COLLECTED"
            )
            .order_by(
                Delivery.collected_at.desc()
            )
            .all()
        )

    # -------------------------------------------------
    # Analytics
    # -------------------------------------------------

    def count_by_status(
        self,
        status: str,
    ):

        return (
            self.db.query(
                func.count(Delivery.id)
            )
            .filter(
                Delivery.status == status
            )
            .scalar()
        )

    def count_by_category(
        self,
        category: str,
    ):

        return (
            self.db.query(
                func.count(Delivery.id)
            )
            .filter(
                Delivery.delivery_category == category
            )
            .scalar()
        )

    # -------------------------------------------------
    # Update
    # -------------------------------------------------

    def save(
        self,
        delivery: Delivery,
    ):

        self.db.commit()

        self.db.refresh(delivery)

        return delivery