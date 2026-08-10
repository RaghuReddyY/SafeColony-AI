from app.handlers.base_handler import BaseHandler

from app.events.vacation_events import (
    VacationStartedEvent,
    VacationCancelledEvent,
)

from app.models.notification import Notification
from app.models.user import User
from app.enums import UserRole


class ResidentNotificationHandler(BaseHandler):

    def handle(self, event):

        # =====================================================
        # Vacation Started
        # =====================================================

        if isinstance(event, VacationStartedEvent):

            # -------------------------------------------------
            # Resident Notification
            # -------------------------------------------------

            resident_user = (
                self.db.query(User)
                .join(User.resident)
                .filter(User.resident.has(id=event.resident_id))
                .first()
            )

            if resident_user:

                self.db.add(
                    Notification(
                        user_id=resident_user.id,
                        title="Vacation Mode Enabled",
                        message=(
                            f"Your Vacation Mode is enabled "
                            f"from {event.start_date} "
                            f"to {event.end_date}."
                        ),
                        notification_type="VACATION",
                    )
                )

            # -------------------------------------------------
            # Organization Admin Notifications
            # -------------------------------------------------

            if resident_user:

                admins = (
                    self.db.query(User)
                    .filter(
                        User.organization_id == resident_user.organization_id,
                        User.role == UserRole.ORGANIZATION_ADMIN.value,
                    )
                    .all()
                )

                for admin in admins:

                    self.db.add(
                        Notification(
                            user_id=admin.id,
                            title="Resident Vacation",
                            message=(
                                f"{event.resident_name} enabled Vacation Mode."
                            ),
                            notification_type="VACATION",
                        )
                    )

            # -------------------------------------------------
            # Guard Notifications
            # -------------------------------------------------

            if resident_user:

                guards = (
                    self.db.query(User)
                    .filter(
                        User.organization_id == resident_user.organization_id,
                        User.role == UserRole.SECURITY_GUARD.value,
                    )
                    .all()
                )

                for guard in guards:

                    self.db.add(
                        Notification(
                            user_id=guard.id,
                            title="Vacation Alert",
                            message=(
                                f"{event.resident_name} is away on vacation."
                            ),
                            notification_type="VACATION",
                        )
                    )

        # =====================================================
        # Vacation Cancelled
        # =====================================================

        elif isinstance(event, VacationCancelledEvent):

            resident_user = (
                self.db.query(User)
                .join(User.resident)
                .filter(User.resident.has(id=event.resident_id))
                .first()
            )

            if resident_user:

                self.db.add(
                    Notification(
                        user_id=resident_user.id,
                        title="Vacation Cancelled",
                        message="Your Vacation Mode has been cancelled.",
                        notification_type="VACATION",
                    )
                )