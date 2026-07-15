from sqlalchemy import func

from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.vacation_mode import VacationMode
from app.models.visitor import Visitor


class DashboardRepository:

    def __init__(self, db):
        self.db = db

    def get_summary(self, resident_id: int):

        resident = (
            self.db.query(Resident)
            .filter(Resident.id == resident_id)
            .first()
        )

        if resident is None:
            return None

        visitor_count = (
            self.db.query(func.count(Visitor.id))
            .filter(Visitor.resident_id == resident_id)
            .scalar()
        )

        pending_visitors = (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.status == "PENDING",
            )
            .scalar()
        )

        delivery_count = (
            self.db.query(func.count(Delivery.id))
            .filter(Delivery.resident_id == resident_id)
            .scalar()
        )

        pending_deliveries = (
            self.db.query(func.count(Delivery.id))
            .filter(
                Delivery.resident_id == resident_id,
                Delivery.status == "ARRIVED",
            )
            .scalar()
        )

        notification_count = (
            self.db.query(func.count(Notification.id))
            .filter(Notification.resident_id == resident_id)
            .scalar()
        )

        unread_notifications = (
            self.db.query(func.count(Notification.id))
            .filter(
                Notification.resident_id == resident_id,
                Notification.is_read == False,
            )
            .scalar()
        )

        vacation = (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == "ACTIVE",
            )
            .first()
        )

        vacation_mode = vacation is not None

        security_score = 100

        security_score -= pending_visitors * 2
        security_score -= pending_deliveries
        security_score -= unread_notifications

        if vacation_mode:
            security_score += 2

            if vacation.monitoring_enabled:
                security_score += 2

        security_score = max(0, min(100, security_score))

        return {
            "resident_name": resident.full_name,
            "unit_number": resident.unit.unit_number,
            "visitor_count": visitor_count,
            "pending_visitors": pending_visitors,
            "delivery_count": delivery_count,
            "pending_deliveries": pending_deliveries,
            "notification_count": notification_count,
            "unread_notifications": unread_notifications,
            "vacation_mode": vacation_mode,
            "security_score": security_score,
        }