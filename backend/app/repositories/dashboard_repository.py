from sqlalchemy import func

from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.vacation_mode import VacationMode
from app.models.visitor import Visitor


class DashboardRepository:

    def __init__(self, db):
        self.db = db

    def get_summary(self, user_id: int):

        # -------------------------------------------------------
        # Find the logged-in user's resident record
        # -------------------------------------------------------
        resident = (
            self.db.query(Resident)
            .filter(Resident.user_id == user_id)
            .first()
        )

        if resident is None:
            return None

        resident_id = resident.id

        # -------------------------------------------------------
        # Visitors
        # -------------------------------------------------------
        visitor_count = (
            self.db.query(func.count(Visitor.id))
            .filter(Visitor.resident_id == resident_id)
            .scalar()
            or 0
        )

        pending_visitors = (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.status == "PENDING",
            )
            .scalar()
            or 0
        )

        # -------------------------------------------------------
        # Deliveries
        # -------------------------------------------------------
        delivery_count = (
            self.db.query(func.count(Delivery.id))
            .filter(Delivery.resident_id == resident_id)
            .scalar()
            or 0
        )

        pending_deliveries = (
            self.db.query(func.count(Delivery.id))
            .filter(
                Delivery.resident_id == resident_id,
                Delivery.status == "ARRIVED",
            )
            .scalar()
            or 0
        )

        # -------------------------------------------------------
        # Notifications
        # -------------------------------------------------------
        notification_count = (
            self.db.query(func.count(Notification.id))
            .filter(Notification.resident_id == resident_id)
            .scalar()
            or 0
        )

        unread_notifications = (
            self.db.query(func.count(Notification.id))
            .filter(
                Notification.resident_id == resident_id,
                Notification.is_read == False,
            )
            .scalar()
            or 0
        )

        # -------------------------------------------------------
        # Vacation Mode
        # -------------------------------------------------------
        vacation = (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == "ACTIVE",
            )
            .first()
        )

        vacation_mode = vacation is not None

        # -------------------------------------------------------
        # Security Score
        # -------------------------------------------------------
        security_score = 100

        security_score -= pending_visitors * 2
        security_score -= pending_deliveries
        security_score -= unread_notifications

        if vacation_mode:
            security_score += 2

            if vacation.monitoring_enabled:
                security_score += 2

        security_score = max(0, min(100, security_score))

        # -------------------------------------------------------
        # Response
        # -------------------------------------------------------
        return {
            "resident_name": resident.full_name,
            "unit_number": resident.unit_number or "Not Assigned",
            "visitor_count": visitor_count,
            "pending_visitors": pending_visitors,
            "delivery_count": delivery_count,
            "pending_deliveries": pending_deliveries,
            "notification_count": notification_count,
            "unread_notifications": unread_notifications,
            "vacation_mode": vacation_mode,
            "security_score": security_score,
        }