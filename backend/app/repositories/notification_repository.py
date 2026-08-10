from sqlalchemy.orm import Session

from app.models.notification import Notification


class NotificationRepository:

    def __init__(self, db: Session):
        self.db = db

    # =====================================================
    # Create
    # =====================================================

    def create(
        self,
        notification: Notification,
    ) -> Notification:

        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)

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