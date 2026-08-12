from app.handlers.base_handler import BaseHandler
from app.events.vacation_events import VacationStartedEvent, VacationCancelledEvent, VacationCompletedEvent
from app.models.notification import Notification
from app.models.user import User
from app.enums import UserRole


class ResidentNotificationHandler(BaseHandler):
    def handle(self, event):
        resident_user = (
            self.db.query(User)
            .join(User.resident)
            .filter(User.resident.has(id=event.resident_id))
            .first()
        )
        if not resident_user:
            return

        admins = self.db.query(User).filter(
            User.organization_id == resident_user.organization_id,
            User.role == UserRole.ORGANIZATION_ADMIN.value,
            User.is_active.is_(True),
        ).all()
        guards = self.db.query(User).filter(
            User.organization_id == resident_user.organization_id,
            User.role == UserRole.SECURITY_GUARD.value,
            User.is_active.is_(True),
        ).all()

        if isinstance(event, VacationStartedEvent):
            resident_message = (
                f"Your Vacation Mode is active from {event.start_date} to {event.end_date}. "
                f"Visitor policy: {event.visitor_policy}; Delivery policy: {event.delivery_policy}."
            )
            self.db.add(Notification(
                user_id=resident_user.id, title="Vacation Mode Enabled",
                message=resident_message, notification_type="VACATION"
            ))
            for admin in admins:
                self.db.add(Notification(
                    user_id=admin.id, title="Resident Vacation",
                    message=(f"{event.resident_name} is away from {event.start_date} to {event.end_date}. "
                             f"Visitor policy: {event.visitor_policy}; Delivery policy: {event.delivery_policy}."),
                    notification_type="VACATION"
                ))
            for guard in guards:
                self.db.add(Notification(
                    user_id=guard.id, title="Vacation Alert",
                    message=(f"{event.resident_name} is away from {event.start_date} to {event.end_date}. "
                             f"Visitor policy: {event.visitor_policy}; Delivery policy: {event.delivery_policy}."),
                    notification_type="VACATION"
                ))

        elif isinstance(event, VacationCompletedEvent):
            self.db.add(Notification(
                user_id=resident_user.id,
                title="Vacation Mode Completed",
                message="Your Vacation Mode has completed.",
                notification_type="VACATION",
            ))
            for admin in admins:
                self.db.add(Notification(
                    user_id=admin.id,
                    title="Vacation Completed",
                    message=f"{event.resident_name}'s Vacation Mode has completed.",
                    notification_type="VACATION",
                ))
            for guard in guards:
                self.db.add(Notification(
                    user_id=guard.id,
                    title="Vacation Completed",
                    message=f"{event.resident_name}'s Vacation Mode has completed.",
                    notification_type="VACATION",
                ))

        elif isinstance(event, VacationCancelledEvent):
            self.db.add(Notification(
                user_id=resident_user.id, title="Vacation Cancelled",
                message="Your Vacation Mode has been cancelled.", notification_type="VACATION"
            ))
            for admin in admins:
                self.db.add(Notification(
                    user_id=admin.id, title="Vacation Cancelled",
                    message=f"{event.resident_name} cancelled Vacation Mode.", notification_type="VACATION"
                ))
            for guard in guards:
                self.db.add(Notification(
                    user_id=guard.id, title="Vacation Cancelled",
                    message=f"{event.resident_name} cancelled Vacation Mode.", notification_type="VACATION"
                ))
