from sqlalchemy.orm import Session

from app.models.delivery import Delivery


class DeliveryRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, delivery: Delivery):

        self.db.add(delivery)
        self.db.commit()
        self.db.refresh(delivery)

        return delivery

    def get_all(self):

        return (
            self.db.query(Delivery)
            .order_by(Delivery.created_at.desc())
            .all()
        )

    def get_by_id(self, delivery_id: int):

        return (
            self.db.query(Delivery)
            .filter(Delivery.id == delivery_id)
            .first()
        )

    def get_by_resident(self, resident_id: int):

        return (
            self.db.query(Delivery)
            .filter(Delivery.resident_id == resident_id)
            .order_by(Delivery.created_at.desc())
            .all()
        )

    def save(self, delivery):

        self.db.commit()
        self.db.refresh(delivery)

        return delivery