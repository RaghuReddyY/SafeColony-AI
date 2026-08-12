from sqlalchemy.orm import Session, joinedload

from app.models.security_alert import SecurityAlert
from app.models.resident import Resident


class SecurityAlertRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, alert: SecurityAlert) -> SecurityAlert:
        self.db.add(alert)
        self.db.flush()
        return alert

    def get_all(self, organization_id: int) -> list[SecurityAlert]:
        return (
            self.db.query(SecurityAlert)
            .options(
                joinedload(SecurityAlert.resident).joinedload(Resident.unit),
                joinedload(SecurityAlert.raised_by),
                joinedload(SecurityAlert.resolved_by),
            )
            .filter(SecurityAlert.organization_id == organization_id)
            .order_by(SecurityAlert.created_at.desc())
            .all()
        )

    def get_unresolved(self, organization_id: int) -> list[SecurityAlert]:
        return (
            self.db.query(SecurityAlert)
            .options(
                joinedload(SecurityAlert.resident).joinedload(Resident.unit),
                joinedload(SecurityAlert.raised_by),
                joinedload(SecurityAlert.resolved_by),
            )
            .filter(
                SecurityAlert.organization_id == organization_id,
                SecurityAlert.is_resolved.is_(False),
            )
            .order_by(SecurityAlert.created_at.desc())
            .all()
        )

    def get_by_id(
        self,
        alert_id: int,
        organization_id: int,
    ) -> SecurityAlert | None:
        return (
            self.db.query(SecurityAlert)
            .options(
                joinedload(SecurityAlert.resident).joinedload(Resident.unit),
                joinedload(SecurityAlert.raised_by),
                joinedload(SecurityAlert.resolved_by),
            )
            .filter(
                SecurityAlert.id == alert_id,
                SecurityAlert.organization_id == organization_id,
            )
            .first()
        )

    def get_by_id_for_raiser(
        self,
        alert_id: int,
        organization_id: int,
        user_id: int,
    ) -> SecurityAlert | None:
        return (
            self.db.query(SecurityAlert)
            .filter(
                SecurityAlert.id == alert_id,
                SecurityAlert.organization_id == organization_id,
                SecurityAlert.raised_by_user_id == user_id,
            )
            .first()
        )

    def save(self, alert: SecurityAlert) -> SecurityAlert:
        self.db.flush()
        self.db.refresh(alert)
        return alert

    def commit(self) -> None:
        self.db.commit()
