from sqlalchemy.orm import Session

from app.models.security_alert import SecurityAlert


class SecurityAlertRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, alert: SecurityAlert):

        self.db.add(alert)
        self.db.commit()
        self.db.refresh(alert)

        return alert

    def get_all(self):

        return (
            self.db.query(SecurityAlert)
            .order_by(SecurityAlert.created_at.desc())
            .all()
        )

    def get_unresolved(self):

        return (
            self.db.query(SecurityAlert)
            .filter(SecurityAlert.is_resolved == False)
            .order_by(SecurityAlert.created_at.desc())
            .all()
        )

    def get_by_id(self, alert_id: int):

        return (
            self.db.query(SecurityAlert)
            .filter(SecurityAlert.id == alert_id)
            .first()
        )

    def save(self, alert):

        self.db.commit()
        self.db.refresh(alert)

        return alert