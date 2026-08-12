from datetime import datetime

from app.core.event_bus import event_bus
from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.events.complaint_events import ComplaintResolvedEvent
from app.models.complaint import Complaint
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.user import User
from app.repositories.complaint_repository import ComplaintRepository


class ComplaintService:
    MANAGE_ROLES = {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER"}

    def __init__(self, repo: ComplaintRepository):
        self.repo = repo
        self.db = repo.db

    def _resident(self, current_user):
        resident = self.db.query(Resident).filter(Resident.user_id == current_user.id).first()
        if not resident:
            raise NotFoundException("Resident")
        if resident.user and resident.user.organization_id != current_user.organization_id:
            raise ForbiddenException("Resident does not belong to your organization.")
        return resident

    def _org_user(self, current_user, user_id):
        user = self.db.query(User).filter(
            User.id == user_id,
            User.organization_id == current_user.organization_id,
            User.is_active.is_(True),
        ).first()
        if not user:
            raise NotFoundException("User")
        return user

    def _notify(self, user_id, title, message):
        self.db.add(Notification(
            user_id=user_id, title=title, message=message, notification_type="COMPLAINT"
        ))

    def create(self, current_user, data):
        resident = self._resident(current_user)
        complaint = Complaint(
            organization_id=current_user.organization_id,
            resident_id=resident.id,
            title=data.title.strip(),
            description=data.description.strip(),
            category=data.category.strip().upper(),
            priority=data.priority.upper(),
            created_by_user_id=current_user.id,
        )
        self.repo.create(complaint)
        self.repo.commit()
        logger.info("Complaint created id=%s resident=%s", complaint.id, resident.id)
        return complaint

    def list(self, current_user, status=None):
        resident_id = None
        if current_user.role == "RESIDENT":
            resident_id = self._resident(current_user).id
        return self.repo.list(current_user.organization_id, resident_id, status)

    def update(self, current_user, complaint_id, data):
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("Only administrators can manage complaints.")
        complaint = self.repo.get_by_id(current_user.organization_id, complaint_id)
        if not complaint:
            raise NotFoundException("Complaint")
        if data.assigned_to_user_id is not None:
            self._org_user(current_user, data.assigned_to_user_id)
            complaint.assigned_to_user_id = data.assigned_to_user_id
            complaint.status = "ASSIGNED" if not data.status else data.status
            self._notify(
                complaint.created_by_user_id,
                "Complaint Assigned",
                f"Complaint #{complaint.id} was assigned for action.",
            )
        if data.status:
            complaint.status = data.status.upper()
        if data.resolution is not None:
            complaint.resolution = data.resolution.strip()
        if complaint.status == "RESOLVED":
            if not complaint.resolution:
                raise BadRequestException("Resolution details are required.")
            complaint.resolved_at = datetime.utcnow()
            event_bus.publish(ComplaintResolvedEvent(
                complaint_id=complaint.id,
                organization_id=complaint.organization_id,
                resident_id=complaint.resident_id,
            ))
            self._notify(
                complaint.created_by_user_id,
                "Complaint Resolved",
                f"Complaint #{complaint.id} has been resolved.",
            )
        elif complaint.status in {"OPEN", "ASSIGNED", "IN_PROGRESS"}:
            complaint.resolved_at = None
        self.repo.commit()
        logger.info("Complaint updated id=%s status=%s", complaint.id, complaint.status)
        return complaint

    def escalate(self, current_user, complaint_id, data):
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("Only administrators can escalate complaints.")
        complaint = self.repo.get_by_id(current_user.organization_id, complaint_id)
        if not complaint:
            raise NotFoundException("Complaint")
        complaint.escalated_at = datetime.utcnow()
        complaint.escalation_reason = data.reason.strip()
        complaint.priority = "CRITICAL"
        self._notify(
            complaint.created_by_user_id,
            "Complaint Escalated",
            f"Complaint #{complaint.id} has been escalated: {complaint.escalation_reason}",
        )
        self.repo.commit()
        return complaint

    def get(self, current_user, complaint_id):
        complaint = self.repo.get_by_id(current_user.organization_id, complaint_id)
        if not complaint:
            raise NotFoundException("Complaint")
        if current_user.role == "RESIDENT" and complaint.created_by_user_id != current_user.id:
            raise ForbiddenException("You can only view your own complaints.")
        return complaint
