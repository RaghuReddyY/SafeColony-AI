from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.notification_device import NotificationDevice
from app.models.notification_template import NotificationDelivery
from app.core.logger import logger
from datetime import datetime


class NotificationRepository:

    def __init__(self, db: Session):
        self.db = db

    # =====================================================
    # Create
    # =====================================================

    def create(
        self,
        notification: Notification,
        enqueue_push: bool = True,
    ) -> Notification:
        """Create an in-app notification and, by default, queue PUSH delivery.

        A number of legacy service paths create Notification rows directly
        through this repository. Previously those rows appeared in the
        SafeColony inbox but never reached the user's phone. Queueing the push
        here closes that gap. NotificationService.create() disables this
        behavior because it already owns channel selection/outbox handling.
        """
        self.db.add(notification)
        self.db.flush()

        if enqueue_push:
            devices = (
                self.db.query(NotificationDevice)
                .filter(
                    NotificationDevice.user_id == notification.user_id,
                    NotificationDevice.is_active.is_(True),
                )
                .all()
            )
            for device in devices:
                self.db.add(NotificationDelivery(
                    notification_id=notification.id,
                    channel="PUSH",
                    destination=device.token,
                    status="PENDING",
                    attempts=0,
                ))

        self.db.commit()
        self.db.refresh(notification)

        if enqueue_push:
            # Attempt immediately so mobile notifications do not wait for the
            # scheduled outbox worker. Failed attempts remain pending for the
            # existing retry job.
            try:
                from app.services import notification_providers
                deliveries = (
                    self.db.query(NotificationDelivery)
                    .filter(
                        NotificationDelivery.notification_id == notification.id,
                        NotificationDelivery.channel == "PUSH",
                        NotificationDelivery.status == "PENDING",
                    )
                    .all()
                )
                for delivery in deliveries:
                    delivery.attempts += 1
                    try:
                        provider_id = notification_providers.send_push(
                            delivery.destination,
                            notification.title,
                            notification.message,
                            data={
                                "type": "CHAT" if (notification.entity_type or notification.notification_type or "").upper() in {"CHAT", "COMMUNITY_CHAT"} else (notification.entity_type or notification.notification_type or "GENERAL"),
                                "entity_type": notification.entity_type,
                                "entity_id": notification.entity_id,
                                "action": notification.action,
                                "notification_id": notification.id,
                            },
                        )
                        delivery.status = "DELIVERED"
                        delivery.provider_message_id = provider_id
                        delivery.sent_at = datetime.utcnow()
                        delivery.last_error = None
                    except Exception as exc:
                        delivery.last_error = str(exc)
                        delivery.status = "PENDING" if delivery.attempts < 5 else "FAILED"
                        logger.warning(
                            "Notification push failed id=%s attempt=%s error=%s",
                            delivery.id, delivery.attempts, exc,
                        )
                self.db.commit()
            except Exception as exc:
                logger.warning("Notification push dispatch failed id=%s error=%s", notification.id, exc)

        return notification

    # =====================================================
    # Queries
    # =====================================================

    def get_by_user(
        self,
        user_id: int,
    ) -> list[Notification]:

        return (
            self.db.query(Notification)
            .filter(
                Notification.user_id == user_id,
            )
            .order_by(
                Notification.created_at.desc(),
            )
            .all()
        )

    def get_unread_by_user(
        self,
        user_id: int,
    ) -> list[Notification]:

        return (
            self.db.query(Notification)
            .filter(
                Notification.user_id == user_id,
                Notification.is_read.is_(False),
            )
            .order_by(
                Notification.created_at.desc(),
            )
            .all()
        )

    def get_unread_count(
        self,
        user_id: int,
    ) -> int:

        return (
            self.db.query(Notification)
            .filter(
                Notification.user_id == user_id,
                Notification.is_read.is_(False),
            )
            .count()
        )

    def get_by_id(
        self,
        notification_id: int,
    ) -> Notification | None:

        return (
            self.db.query(Notification)
            .filter(
                Notification.id == notification_id,
            )
            .first()
        )

    # =====================================================
    # Save
    # =====================================================

    def save(
        self,
        notification: Notification,
    ) -> Notification:

        self.db.commit()
        self.db.refresh(notification)

        return notification

    # =====================================================
    # Bulk Operations
    # =====================================================

    def mark_all_as_read(
        self,
        user_id: int,
    ):

        (
            self.db.query(Notification)
            .filter(
                Notification.user_id == user_id,
                Notification.is_read.is_(False),
            )
            .update(
                {
                    Notification.is_read: True,
                },
                synchronize_session=False,
            )
        )

        self.db.commit()