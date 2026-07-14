from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor
from app.models.vacation_mode import VacationMode


class SecurityDashboardRepository:

    def __init__(self, db: Session):
        self.db = db

    def get_dashboard(self):

        active_alerts = (
            self.db.query(func.count(SecurityAlert.id))
            .filter(SecurityAlert.is_resolved == False)
            .scalar()
        )

        vacation_homes = (
            self.db.query(func.count(VacationMode.id))
            .filter(VacationMode.status == "ACTIVE")
            .scalar()
        )

        visitors_inside = (
            self.db.query(func.count(Visitor.id))
            .filter(Visitor.status == "CHECKED_IN")
            .scalar()
        )

        pending_visitors = (
            self.db.query(func.count(Visitor.id))
            .filter(Visitor.status == "PENDING")
            .scalar()
        )

        vehicles_inside = (
            self.db.query(func.count(Vehicle.id))
            .scalar()
        )

        unread_notifications = (
            self.db.query(func.count(Notification.id))
            .filter(Notification.is_read == False)
            .scalar()
        )

        latest_alerts = (
            self.db.query(SecurityAlert)
            .order_by(SecurityAlert.created_at.desc())
            .limit(10)
            .all()
        )

        return {
            "active_alerts": active_alerts,
            "vacation_homes": vacation_homes,
            "visitors_inside": visitors_inside,
            "pending_visitors": pending_visitors,
            "vehicles_inside": vehicles_inside,
            "unread_notifications": unread_notifications,
            "latest_alerts": latest_alerts,
        }