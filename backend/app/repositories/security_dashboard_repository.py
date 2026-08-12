from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor
from app.models.vacation_mode import VacationMode
from app.models.user import User
from app.models.resident import Resident


class SecurityDashboardRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_dashboard(self, organization_id: int):
        active_alerts = (
            self.db.query(func.count(SecurityAlert.id))
            .filter(
                SecurityAlert.organization_id == organization_id,
                SecurityAlert.is_resolved.is_(False),
            )
            .scalar()
            or 0
        )

        vacation_homes = (
            self.db.query(func.count(VacationMode.id))
            .join(Resident, Resident.id == VacationMode.resident_id)
            .join(User, User.id == Resident.user_id)
            .filter(VacationMode.status == "ACTIVE", User.organization_id == organization_id)
            .scalar()
            or 0
        )

        visitors_inside = (
            self.db.query(func.count(Visitor.id))
            .join(Resident, Resident.id == Visitor.resident_id)
            .join(User, User.id == Resident.user_id)
            .filter(Visitor.status == "CHECKED_IN", User.organization_id == organization_id)
            .scalar()
            or 0
        )

        pending_visitors = (
            self.db.query(func.count(Visitor.id))
            .join(Resident, Resident.id == Visitor.resident_id)
            .join(User, User.id == Resident.user_id)
            .filter(Visitor.status == "PENDING", User.organization_id == organization_id)
            .scalar()
            or 0
        )

        vehicles_inside = (
            self.db.query(func.count(Vehicle.id))
            .join(Resident, Resident.id == Vehicle.resident_id)
            .join(User, User.id == Resident.user_id)
            .filter(User.organization_id == organization_id)
            .scalar()
            or 0
        )

        unread_notifications = (
            self.db.query(func.count(Notification.id))
            .join(User, Notification.user_id == User.id)
            .filter(
                User.organization_id == organization_id,
                Notification.is_read.is_(False),
            )
            .scalar()
            or 0
        )

        latest_alerts = (
            self.db.query(SecurityAlert)
            .options(
                joinedload(SecurityAlert.resident).joinedload(Resident.unit),
                joinedload(SecurityAlert.raised_by),
                joinedload(SecurityAlert.resolved_by),
            )
            .filter(SecurityAlert.organization_id == organization_id)
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
