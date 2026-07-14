from fastapi import HTTPException

from app.models.notification import Notification


class NotificationService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):

        notification = Notification(
            resident_id=data.resident_id,
            title=data.title,
            message=data.message,
            notification_type=data.notification_type,
        )

        return self.repo.create(notification)

    def get_by_resident(self, resident_id: int):
        return self.repo.get_by_resident(resident_id)

    def mark_as_read(self, notification_id: int):

        notification = self.repo.get_by_id(notification_id)

        if notification is None:
            raise HTTPException(
                status_code=404,
                detail="Notification not found",
            )

        notification.is_read = True

        return self.repo.save(notification)