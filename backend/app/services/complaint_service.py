from datetime import datetime
from pathlib import Path

from app.core.event_bus import event_bus
from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.events.complaint_events import ComplaintResolvedEvent
from app.models.complaint import Complaint
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.user import User
from app.models.user_block_scope import UserBlockScope
from app.repositories.complaint_repository import ComplaintRepository
from app.services.scope_service import ScopeService
from app.services.storage_service import StorageService


class ComplaintService:
    MANAGE_ROLES = {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "BLOCK_ADMIN"}

    def __init__(self, repo: ComplaintRepository):
        self.repo = repo
        self.db = repo.db

    def _response(self, complaint):
        return {
            "id": complaint.id,
            "organization_id": complaint.organization_id,
            "resident_id": complaint.resident_id,
            "title": complaint.title,
            "description": complaint.description,
            "category": complaint.category,
            "priority": complaint.priority,
            "status": complaint.status,
            "assigned_to_user_id": complaint.assigned_to_user_id,
            "escalated_at": complaint.escalated_at,
            "escalation_reason": complaint.escalation_reason,
            "resolution": complaint.resolution,
            "resolved_at": complaint.resolved_at,
            "created_by_user_id": complaint.created_by_user_id,
            "created_at": complaint.created_at,
            "updated_at": complaint.updated_at,
            "attachments": [
                {
                    "id": a.id,
                    "file_name": a.file_name,
                    "content_type": a.content_type,
                    "file_size": a.file_size,
                    "file_url": StorageService().url_for(a.file_path),
                    "created_at": a.created_at,
                }
                for a in (complaint.attachments or [])
            ],
        }

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

    def _notify(self, user_id, title, message, complaint_id=None):
        if user_id is None:
            return
        self.db.add(Notification(
            user_id=user_id, title=title, message=message, notification_type="COMPLAINT",
            entity_type="COMPLAINT", entity_id=complaint_id, action="OPEN_COMPLAINT"
        ))

    def _notify_roles(self, organization_id, roles, title, message, exclude_user_id=None, section_id=None, complaint_id=None):
        users = (
            self.db.query(User)
            .filter(
                User.organization_id == organization_id,
                User.role.in_(list(roles)),
                User.is_active.is_(True),
            )
            .all()
        )
        if section_id is not None:
            scoped_ids = {
                row[0] for row in self.db.query(UserBlockScope.user_id).filter(UserBlockScope.section_id == section_id).all()
            }
            users = [u for u in users if u.role != "BLOCK_ADMIN" or u.id in scoped_ids]
        for user in users:
            if exclude_user_id is not None and user.id == exclude_user_id:
                continue
            self._notify(user.id, title, message, complaint_id=complaint_id)

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
        self.db.flush()

        # A new complaint is operational work. Notify the administrators and
        # security team so it is visible without requiring them to poll the
        # complaints screen. The resident who created it is not notified about
        # their own submission.
        self._notify_roles(
            complaint.organization_id,
            {
                "ORGANIZATION_ADMIN",
                "PROPERTY_MANAGER",
                "SECURITY_MANAGER",
                "SECURITY_GUARD",
                "BLOCK_ADMIN",
            },
            f"New Complaint #{complaint.id}",
            f"{complaint.priority} complaint: {complaint.title}.",
            exclude_user_id=current_user.id,
            section_id=resident.unit.section_id if resident.unit else None,
            complaint_id=complaint.id,
        )
        self.repo.commit()
        logger.info("Complaint created id=%s resident=%s", complaint.id, resident.id)
        return self._response(complaint)

    def list(self, current_user, status=None):
        resident_id = None
        if current_user.role == "RESIDENT":
            resident_id = self._resident(current_user).id
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        return [self._response(c) for c in self.repo.list(current_user.organization_id, resident_id, status, section_ids)]

    def update(self, current_user, complaint_id, data):
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("Only administrators can manage complaints.")
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        complaint = self.repo.get_by_id(current_user.organization_id, complaint_id, section_ids)
        if not complaint:
            raise NotFoundException("Complaint")

        previous_status = complaint.status.upper() if complaint.status else "OPEN"

        if data.assigned_to_user_id is not None:
            assigned_user = self._org_user(current_user, data.assigned_to_user_id)
            complaint.assigned_to_user_id = assigned_user.id
            complaint.status = "ASSIGNED" if not data.status else data.status
            self._notify(
                complaint.created_by_user_id,
                "Complaint Assigned",
                f"Complaint #{complaint.id} was assigned to {assigned_user.full_name}.",
            )
            if assigned_user.id != current_user.id:
                self._notify(
                    assigned_user.id,
                    "Complaint Assigned To You",
                    f"Complaint #{complaint.id}: {complaint.title} requires action.",
                )
        if data.status:
            complaint.status = data.status.upper()
        if data.resolution is not None:
            complaint.resolution = data.resolution.strip()
        if complaint.status in {"RESOLVED", "CLOSED"}:
            # RESOLVED requires resolution details. CLOSED remains compatible
            # with the existing UI/API, where the admin may close a complaint
            # without entering a separate resolution note.
            if complaint.status == "RESOLVED" and not complaint.resolution:
                raise BadRequestException("Resolution details are required when resolving a complaint.")

            # Notify only when the complaint actually enters a terminal state.
            # This prevents duplicate notifications when an admin edits an already
            # resolved complaint later.
            transitioned_to_terminal = previous_status not in {"RESOLVED", "CLOSED"}
            complaint.resolved_at = complaint.resolved_at or datetime.utcnow()

            if transitioned_to_terminal:
                event_bus.publish(ComplaintResolvedEvent(
                    complaint_id=complaint.id,
                    organization_id=complaint.organization_id,
                    resident_id=complaint.resident_id,
                ))

                status_label = "resolved" if complaint.status == "RESOLVED" else "closed"
                self._notify(
                    complaint.created_by_user_id,
                    f"Complaint {status_label.title()}",
                    f"Complaint #{complaint.id} has been {status_label}."
                    + (f" {complaint.resolution}" if complaint.resolution else ""),
                )

                if complaint.assigned_to_user_id and complaint.assigned_to_user_id != current_user.id:
                    self._notify(
                        complaint.assigned_to_user_id,
                        f"Complaint {status_label.title()}",
                        f"Complaint #{complaint.id} has been {status_label}.",
                    )
        elif complaint.status in {"OPEN", "ASSIGNED", "IN_PROGRESS"}:
            complaint.resolved_at = None
        self.repo.commit()
        logger.info("Complaint updated id=%s status=%s", complaint.id, complaint.status)
        return self._response(complaint)

    def escalate(self, current_user, complaint_id, data):
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("Only administrators can escalate complaints.")
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        complaint = self.repo.get_by_id(current_user.organization_id, complaint_id, section_ids)
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
        self._notify_roles(
            complaint.organization_id,
            {"ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "SECURITY_MANAGER", "BLOCK_ADMIN"},
            f"Complaint #{complaint.id} Escalated",
            complaint.escalation_reason or "Complaint requires escalation.",
            exclude_user_id=current_user.id,
            section_id=complaint.resident.unit.section_id if complaint.resident and complaint.resident.unit else None,
        )
        self.repo.commit()
        return self._response(complaint)

    async def add_attachment(self, current_user, complaint_id: int, upload):
        complaint = self.get(current_user, complaint_id)
        # get() returns the safe response, so load the ORM object again for persistence.
        section_ids = ScopeService.block_ids(self.db, current_user) if current_user.role == "BLOCK_ADMIN" else None
        complaint_obj = self.repo.get_by_id(current_user.organization_id, complaint_id, section_ids)
        if not complaint_obj:
            raise NotFoundException("Complaint")
        content_type = (upload.content_type or "").lower()
        allowed = {
            "image/jpeg", "image/png", "image/webp", "image/gif",
            "application/pdf",
        }
        if content_type not in allowed:
            raise BadRequestException("Unsupported attachment type. Use JPG, PNG, WEBP, GIF or PDF.")
        filename = (upload.filename or "attachment").strip()
        extension = Path(filename).suffix.lower()
        allowed_ext = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".pdf"}
        if extension not in allowed_ext:
            raise BadRequestException("Unsupported attachment extension.")
        content = await upload.read()
        if not content:
            raise BadRequestException("Attachment is empty.")
        if len(content) > 10 * 1024 * 1024:
            raise BadRequestException("Complaint attachment must be 10 MB or smaller.")
        from uuid import uuid4
        from app.models.complaint_attachment import ComplaintAttachment
        stored = StorageService().upload_bytes(
            f"complaints/{complaint_obj.id}/{uuid4().hex}{extension}",
            content,
            content_type=content_type,
        )
        attachment = ComplaintAttachment(
            complaint_id=complaint_obj.id,
            uploaded_by_user_id=current_user.id,
            file_name=filename[:255],
            content_type=content_type,
            file_size=len(content),
            file_path=stored,
        )
        self.db.add(attachment)
        self.db.commit()
        self.db.refresh(attachment)
        return {
            "id": attachment.id,
            "file_name": attachment.file_name,
            "content_type": attachment.content_type,
            "file_size": attachment.file_size,
            "file_url": StorageService().url_for(attachment.file_path),
            "created_at": attachment.created_at,
        }

    def get(self, current_user, complaint_id):
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        complaint = self.repo.get_by_id(current_user.organization_id, complaint_id, section_ids)
        if not complaint:
            raise NotFoundException("Complaint")
        if current_user.role == "RESIDENT" and complaint.created_by_user_id != current_user.id:
            raise ForbiddenException("You can only view your own complaints.")
        return self._response(complaint)
