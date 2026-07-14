from app.handlers.base_handler import BaseHandler

from app.models.notification import Notification


class ResidentNotificationHandler(BaseHandler):

    def handle(self, event):

        notification = Notification(
            resident_id=event.resident_id,
            title="Vacation Mode Enabled",
            message=(
                f"Vacation Mode enabled "
                f"from {event.start_date} "
                f"to {event.end_date}"
            ),
            notification_type="VACATION",
        )

        self.db.add(notification)