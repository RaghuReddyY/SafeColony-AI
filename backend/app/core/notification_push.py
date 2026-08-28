"""Automatic mobile push dispatch for every SafeColony notification.

Notifications are written by several services directly to the database.  This
module hooks into SQLAlchemy's transaction lifecycle so all of those paths get
the same FCM behaviour without requiring each service to remember to enqueue a
push notification.
"""

from datetime import datetime

from sqlalchemy import event
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.notification_device import NotificationDevice
from app.models.notification_template import NotificationDelivery


def _before_flush(session: Session, flush_context, instances) -> None:
    pending = session.info.setdefault("_safe_colony_new_notifications", [])
    seen = {id(obj) for obj in pending}

    for obj in session.new:
        if isinstance(obj, Notification) and id(obj) not in seen:
            pending.append(obj)
            seen.add(id(obj))


def _after_flush_postexec(session: Session, flush_context) -> None:
    pending = session.info.pop("_safe_colony_new_notifications", [])
    if not pending:
        return

    ids = session.info.setdefault("_safe_colony_notification_push_ids", set())
    for notification in pending:
        if notification.id is not None:
            ids.add(notification.id)


def _after_rollback(session: Session) -> None:
    session.info.pop("_safe_colony_new_notifications", None)
    session.info.pop("_safe_colony_notification_push_ids", None)


def _after_commit(session: Session) -> None:
    notification_ids = session.info.pop(
        "_safe_colony_notification_push_ids",
        set(),
    )
    session.info.pop("_safe_colony_new_notifications", None)

    if not notification_ids:
        return

    # The original transaction is already committed. Use a fresh session for
    # device lookup and delivery updates so push failures can never roll back
    # the notification itself.
    from app.database.session import SessionLocal
    from app.services import notification_providers

    db = SessionLocal()
    try:
        notifications = (
            db.query(Notification)
            .filter(Notification.id.in_(notification_ids))
            .all()
        )

        for notification in notifications:
            devices = (
                db.query(NotificationDevice)
                .filter(
                    NotificationDevice.user_id == notification.user_id,
                    NotificationDevice.is_active.is_(True),
                )
                .all()
            )

            for device in devices:
                delivery = (
                    db.query(NotificationDelivery)
                    .filter(
                        NotificationDelivery.notification_id == notification.id,
                        NotificationDelivery.channel == "PUSH",
                        NotificationDelivery.destination == device.token,
                    )
                    .first()
                )

                if delivery is None:
                    delivery = NotificationDelivery(
                        notification_id=notification.id,
                        channel="PUSH",
                        destination=device.token,
                        status="PENDING",
                        attempts=0,
                    )
                    db.add(delivery)
                    db.flush()

                if delivery.status == "DELIVERED":
                    continue

                delivery.attempts += 1
                try:
                    provider_id = notification_providers.send_push(
                        device.token,
                        notification.title,
                        notification.message,
                        data={
                            "type": notification.notification_type,
                            "entity_type": notification.entity_type,
                            "entity_id": notification.entity_id,
                            "action": notification.action,
                            "notification_id": notification.id,
                        },
                    )
                    delivery.status = "DELIVERED"
                    delivery.provider_message_id = provider_id
                    delivery.last_error = None
                    delivery.sent_at = datetime.utcnow()
                except Exception as exc:
                    delivery.status = "PENDING" if delivery.attempts < 5 else "FAILED"
                    delivery.last_error = str(exc)

        db.commit()
    except Exception:
        db.rollback()
        from app.core.logger import logger
        logger.exception(
            "Automatic notification push dispatch failed for notification ids=%s",
            sorted(notification_ids),
        )
    finally:
        db.close()


# Register once when this module is imported.
event.listen(Session, "before_flush", _before_flush)
event.listen(Session, "after_flush_postexec", _after_flush_postexec)
event.listen(Session, "after_rollback", _after_rollback)
event.listen(Session, "after_commit", _after_commit)
