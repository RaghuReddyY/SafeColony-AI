from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.incident import Incident, IncidentEvidence


class IncidentRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, incident):
        self.db.add(incident)
        self.db.flush()
        return incident

    def get_by_id(self, organization_id: int, incident_id: int):
        return (
            self.db.query(Incident)
            .options(joinedload(Incident.evidence))
            .filter(Incident.id == incident_id, Incident.organization_id == organization_id)
            .first()
        )

    def list(self, organization_id: int, status: str | None = None):
        q = (
            self.db.query(Incident)
            .options(joinedload(Incident.evidence))
            .filter(Incident.organization_id == organization_id)
        )
        if status:
            q = q.filter(Incident.status == status)
        return q.order_by(Incident.created_at.desc()).all()

    def create_evidence(self, evidence):
        self.db.add(evidence)
        self.db.flush()
        return evidence

    def report(self, organization_id: int):
        rows = (
            self.db.query(Incident.status, func.count(Incident.id))
            .filter(Incident.organization_id == organization_id)
            .group_by(Incident.status)
            .all()
        )
        severity_rows = (
            self.db.query(func.count(Incident.id))
            .filter(
                Incident.organization_id == organization_id,
                Incident.severity == "CRITICAL",
            )
            .scalar() or 0
        )
        values = dict(rows)
        total = sum(values.values())
        return {
            "total": total,
            "open": values.get("OPEN", 0),
            "investigating": values.get("INVESTIGATING", 0),
            "resolved": values.get("RESOLVED", 0),
            "closed": values.get("CLOSED", 0),
            "critical": severity_rows,
        }

    def commit(self):
        self.db.commit()
