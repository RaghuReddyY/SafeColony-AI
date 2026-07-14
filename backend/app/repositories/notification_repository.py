from sqlalchemy.orm import Session

from app.models.notification import Notification


class NotificationRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, notification: Notification):
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def get_by_resident(self, resident_id: int):
        return (
            self.db.query(Notification)
            .filter(Notification.resident_id == resident_id)
            .order_by(Notification.created_at.desc())
            .all()
        )

    def get_by_id(self, notification_id: int):
        return (
            self.db.query(Notification)
            .filter(Notification.id == notification_id)
            .first()
        )

    def save(self, notification: Notification):
        self.db.commit()
        self.db.refresh(notification)
        return notification