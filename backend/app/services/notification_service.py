from fastapi import HTTPException

from app.models.notification import Notification


class NotificationService:

    def __init__(self, repo):
        self.repo = repo

    # =====================================================
    # Create Notification
    # =====================================================

    def create(self, data):

        notification = Notification(
            user_id=data.user_id,
            title=data.title,
            message=data.message,
            notification_type=data.notification_type,
        )

        return self.repo.create(notification)

    # =====================================================
    # Get User Notifications
    # =====================================================

    def get_by_user(
        self,
        user_id: int,
    ):

        return self.repo.get_by_user(user_id)

    # =====================================================
    # Get Resident Notifications
    # =====================================================

    def get_by_resident(
        self,
        resident_id: int,
    ):

        return self.repo.get_by_user(resident_id)

    # =====================================================
    # Get Unread Count
    # =====================================================

    def unread_count(
        self,
        user_id: int,
    ):

        return {
            "count": self.repo.get_unread_count(user_id)
        }

    # =====================================================
    # Mark Single Notification Read
    # =====================================================

    def mark_as_read(
        self,
        notification_id: int,
    ):

        notification = self.repo.get_by_id(
            notification_id,
        )

        if notification is None:
            raise HTTPException(
                status_code=404,
                detail="Notification not found",
            )

        notification.is_read = True

        return self.repo.save(notification)

    # =====================================================
    # Mark All Read
    # =====================================================

    def mark_all_as_read(
        self,
        user_id: int,
    ):

        self.repo.mark_all_as_read(user_id)

        return {
            "message": "All notifications marked as read."
        }