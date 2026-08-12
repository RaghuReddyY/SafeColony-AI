from sqlalchemy.orm import Session

from app.models.complaint import Complaint


class ComplaintRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, complaint):
        self.db.add(complaint)
        self.db.flush()
        return complaint

    def get_by_id(self, organization_id, complaint_id):
        return (
            self.db.query(Complaint)
            .filter(
                Complaint.id == complaint_id,
                Complaint.organization_id == organization_id,
            )
            .first()
        )

    def list(self, organization_id, resident_id=None, status=None):
        q = self.db.query(Complaint).filter(Complaint.organization_id == organization_id)
        if resident_id is not None:
            q = q.filter(Complaint.resident_id == resident_id)
        if status:
            q = q.filter(Complaint.status == status)
        return q.order_by(Complaint.created_at.desc()).all()

    def commit(self):
        self.db.commit()
