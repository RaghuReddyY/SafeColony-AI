from datetime import datetime

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.models.notification import Notification
from app.models.notification_template import NotificationDelivery, NotificationTemplate
from app.models.notification_device import NotificationDevice
from app.models.user import User
from app.repositories.notification_repository import NotificationRepository
from app.repositories.notification_template_repository import NotificationTemplateRepository


class NotificationService:
    """Notification history plus channel/outbox management."""

    CHANNELS = {"IN_APP", "PUSH", "EMAIL", "SMS", "WHATSAPP"}
    ADMIN_ROLES = {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER"}

    def __init__(self, repo: NotificationRepository):
        self.repo = repo
        self.db = repo.db
        self.template_repo = NotificationTemplateRepository(self.db)

    def _organization_user(self, current_user: User, user_id: int):
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise NotFoundException("User")
        if current_user.role != "SYSTEM_ADMIN" and user.organization_id != current_user.organization_id:
            raise ForbiddenException("User does not belong to your organization.")
        return user

    def create(self, data, current_user: User | None = None):
        if current_user and current_user.role != "SYSTEM_ADMIN":
            target = self._organization_user(current_user, data.user_id)
        else:
            target = self.db.query(User).filter(User.id == data.user_id).first()
            if not target:
                raise NotFoundException("User")

        notification = Notification(
            user_id=target.id,
            title=data.title,
            message=data.message,
            notification_type=data.notification_type,
        )
        self.db.add(notification)
        self.db.flush()

        channel = getattr(data, "channel", "IN_APP") or "IN_APP"
        if channel not in self.CHANNELS:
            raise BadRequestException("Unsupported notification channel.")
        if channel == "PUSH":
            devices = self.template_repo.list_devices(target.id)
            if not devices:
                self._queue_delivery(notification, channel, str(target.id))
            else:
                for device in devices:
                    self._queue_delivery(notification, channel, device.token)
        else:
            self._queue_delivery(notification, channel, self._destination(target, channel))
        self.db.commit()
        self.db.refresh(notification)
        logger.info("Notification created user=%s type=%s channel=%s", target.id, data.notification_type, channel)
        return notification

    def _destination(self, user: User, channel: str):
        if channel == "EMAIL":
            return user.email
        if channel in {"SMS", "WHATSAPP"}:
            return user.phone
        return str(user.id)

    def _queue_delivery(self, notification: Notification, channel: str, destination: str | None):
        self.db.add(NotificationDelivery(
            notification_id=notification.id,
            channel=channel,
            destination=destination,
            status="PENDING" if channel != "IN_APP" else "DELIVERED",
            attempts=0 if channel != "IN_APP" else 1,
            sent_at=datetime.utcnow() if channel == "IN_APP" else None,
        ))

    def get_by_user(self, user_id: int):
        return self.repo.get_by_user(user_id)

    def get_by_resident(self, resident_id: int):
        # Kept for compatibility; callers should use user_id because notifications belong to users.
        return self.repo.get_by_user(resident_id)

    def unread_count(self, user_id: int):
        return {"count": self.repo.get_unread_count(user_id)}

    def mark_as_read(self, notification_id: int, current_user: User | None = None):
        notification = self.repo.get_by_id(notification_id)
        if notification is None:
            raise NotFoundException("Notification")
        if current_user and current_user.role != "SYSTEM_ADMIN" and notification.user_id != current_user.id:
            raise ForbiddenException("You can only update your own notifications.")
        notification.is_read = True
        return self.repo.save(notification)

    def mark_all_as_read(self, user_id: int, current_user: User | None = None):
        if current_user and current_user.role != "SYSTEM_ADMIN" and user_id != current_user.id:
            raise ForbiddenException("You can only update your own notifications.")
        self.repo.mark_all_as_read(user_id)
        return {"message": "All notifications marked as read."}

    def list_templates(self, current_user: User):
        return self.template_repo.list_templates(current_user.organization_id)

    def create_template(self, current_user: User, data):
        if current_user.role not in self.ADMIN_ROLES:
            raise ForbiddenException("Only administrators can manage notification templates.")
        channel = data.channel.upper()
        if channel not in self.CHANNELS:
            raise BadRequestException("Unsupported notification channel.")
        existing = self.template_repo.get_template(current_user.organization_id, data.code)
        if existing:
            raise BadRequestException("Notification template already exists.")
        template = NotificationTemplate(
            organization_id=current_user.organization_id,
            code=data.code.strip().upper(),
            title_template=data.title_template,
            message_template=data.message_template,
            channel=channel,
        )
        self.template_repo.save_template(template)
        self.db.commit()
        return template

    def render_template(self, template, variables: dict):
        class SafeDict(dict):
            def __missing__(self, key):
                return "{" + key + "}"
        values = SafeDict(variables)
        return template.title_template.format_map(values), template.message_template.format_map(values)

    def register_device(self, current_user: User, data):
        existing = self.template_repo.get_device(current_user.id, data.token)
        if existing:
            existing.platform = data.platform.upper()
            existing.is_active = True
            self.db.commit()
            return existing
        device = NotificationDevice(
            user_id=current_user.id,
            token=data.token,
            platform=data.platform.upper(),
            is_active=True,
        )
        self.template_repo.save_device(device)
        self.db.commit()
        return device

    def list_devices(self, current_user):
        return self.template_repo.list_devices(current_user.id)

    def process_pending_deliveries(self, limit: int = 100):
        """Process outbox records.

        External provider credentials are intentionally optional. Without a configured
        provider, the delivery remains FAILED with an actionable error instead of
        pretending that an SMS/email/WhatsApp was sent.
        """
        deliveries = self.template_repo.pending_deliveries(limit)
        processed = 0
        from app.services import notification_providers

        for delivery in deliveries:
            delivery.attempts += 1
            notification = delivery.notification
            try:
                if delivery.channel == "PUSH":
                    provider_id = notification_providers.send_push(
                        delivery.destination, notification.title, notification.message
                    )
                elif delivery.channel == "EMAIL":
                    provider_id = notification_providers.send_email(
                        delivery.destination, notification.title, notification.message
                    )
                elif delivery.channel == "SMS":
                    provider_id = notification_providers.send_sms(
                        delivery.destination, notification.message
                    )
                elif delivery.channel == "WHATSAPP":
                    provider_id = notification_providers.send_whatsapp(
                        delivery.destination, notification.message
                    )
                else:
                    provider_id = "IN_APP"
                delivery.status = "DELIVERED"
                delivery.provider_message_id = provider_id
                delivery.last_error = None
                delivery.sent_at = datetime.utcnow()
            except Exception as exc:
                delivery.status = "PENDING" if delivery.attempts < 5 else "FAILED"
                delivery.last_error = str(exc)
                logger.warning(
                    "Notification delivery failed id=%s channel=%s attempt=%s error=%s",
                    delivery.id, delivery.channel, delivery.attempts, exc,
                )
            processed += 1
        self.db.commit()
        if processed:
            logger.info("Notification outbox processed=%s", processed)
        return processed
