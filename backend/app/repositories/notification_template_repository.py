from sqlalchemy.orm import Session

from app.models.notification_template import NotificationTemplate, NotificationDelivery
from app.models.notification_device import NotificationDevice


class NotificationTemplateRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_templates(self, organization_id: int):
        return (
            self.db.query(NotificationTemplate)
            .filter(NotificationTemplate.organization_id == organization_id)
            .order_by(NotificationTemplate.code.asc())
            .all()
        )

    def get_template(self, organization_id: int, code: str):
        return (
            self.db.query(NotificationTemplate)
            .filter(
                NotificationTemplate.organization_id == organization_id,
                NotificationTemplate.code == code,
                NotificationTemplate.is_active.is_(True),
            )
            .first()
        )

    def save_template(self, template: NotificationTemplate):
        self.db.add(template)
        self.db.flush()
        return template

    def get_delivery(self, delivery_id: int):
        return self.db.query(NotificationDelivery).filter(NotificationDelivery.id == delivery_id).first()

    def pending_deliveries(self, limit: int = 100):
        return (
            self.db.query(NotificationDelivery)
            .filter(
                NotificationDelivery.status.in_(["PENDING", "FAILED"]),
                NotificationDelivery.attempts < 5,
            )
            .order_by(NotificationDelivery.created_at.asc())
            .limit(limit)
            .all()
        )

    def save_delivery(self, delivery: NotificationDelivery):
        self.db.add(delivery)
        self.db.flush()
        return delivery

    def commit(self):
        self.db.commit()


    def get_device(self, user_id: int, token: str):
        return (
            self.db.query(NotificationDevice)
            .filter(NotificationDevice.user_id == user_id, NotificationDevice.token == token)
            .first()
        )

    def list_devices(self, user_id: int):
        return (
            self.db.query(NotificationDevice)
            .filter(NotificationDevice.user_id == user_id, NotificationDevice.is_active.is_(True))
            .order_by(NotificationDevice.created_at.desc())
            .all()
        )

    def save_device(self, device):
        self.db.add(device)
        self.db.flush()
        return device
