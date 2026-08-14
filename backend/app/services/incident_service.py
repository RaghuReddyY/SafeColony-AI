from datetime import datetime
from pathlib import Path
from uuid import uuid4

from app.core.event_bus import event_bus
from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.events.incident_events import IncidentCreatedEvent
from app.models.incident import Incident, IncidentEvidence
from app.models.notification import Notification
from app.models.user import User
from app.models.user_block_scope import UserBlockScope
from app.repositories.incident_repository import IncidentRepository
from app.services.scope_service import ScopeService
from app.models.resident import Resident


class IncidentService:
    MANAGE_ROLES = {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "SECURITY_MANAGER", "BLOCK_ADMIN"}

    def __init__(self, repo: IncidentRepository):
        self.repo = repo
        self.db = repo.db

    def _response(self, incident):
        return {
            "id": incident.id,
            "organization_id": incident.organization_id,
            "section_id": incident.section_id,
            "title": incident.title,
            "description": incident.description,
            "incident_type": incident.incident_type,
            "severity": incident.severity,
            "status": incident.status,
            "location": incident.location,
            "created_by_user_id": incident.created_by_user_id,
            "assigned_to_user_id": incident.assigned_to_user_id,
            "investigation_notes": incident.investigation_notes,
            "resolution_notes": incident.resolution_notes,
            "resolved_at": incident.resolved_at,
            "created_at": incident.created_at,
            "updated_at": incident.updated_at,
            "evidence": incident.evidence or [],
        }

    def _org_user(self, current_user, user_id):
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise NotFoundException("User")
        if user.organization_id != current_user.organization_id:
            raise ForbiddenException("User does not belong to your organization.")
        return user

    def create(self, current_user, data):
        if not current_user.organization_id:
            raise ForbiddenException("User is not associated with an organization.")
        section_id = None
        if current_user.role == "RESIDENT":
            resident = self.db.query(Resident).filter(Resident.user_id == current_user.id).first()
            section_id = resident.unit.section_id if resident and resident.unit else None
        elif current_user.role == "BLOCK_ADMIN":
            scoped = ScopeService.block_ids(self.db, current_user)
            section_id = scoped[0] if len(scoped) == 1 else None

        incident = Incident(
            organization_id=current_user.organization_id,
            section_id=section_id,
            title=data.title.strip(),
            description=data.description.strip(),
            incident_type=data.incident_type.strip().upper(),
            severity=data.severity.upper(),
            location=data.location.strip() if data.location else None,
            created_by_user_id=current_user.id,
        )
        self.repo.create(incident)
        self.db.flush()
        event_bus.publish(IncidentCreatedEvent(
            incident_id=incident.id,
            organization_id=incident.organization_id,
            created_by_user_id=current_user.id,
            title=incident.title,
        ))
        self._notify_roles(
            incident.organization_id,
            {
                "ORGANIZATION_ADMIN",
                "PROPERTY_MANAGER",
                "SECURITY_MANAGER",
                "SECURITY_GUARD",
                "BLOCK_ADMIN",
            },
            f"Incident Created: {incident.title}",
            f"{incident.severity} incident reported at {incident.location or 'community'}.",
            section_id=incident.section_id,
        )
        self.repo.commit()
        logger.warning("Incident created id=%s org=%s severity=%s", incident.id, incident.organization_id, incident.severity)
        return self._response(incident)

    def _notify(self, user_id, title, message):
        if user_id is None:
            return
        self.db.add(Notification(
            user_id=user_id, title=title, message=message, notification_type="INCIDENT"
        ))

    def _notify_roles(self, organization_id, roles, title, message, exclude_user_id=None, section_id=None):
        users = self.db.query(User).filter(
            User.organization_id == organization_id,
            User.role.in_(list(roles)),
            User.is_active.is_(True),
        ).all()
        if section_id is not None:
            scoped_ids = {row[0] for row in self.db.query(UserBlockScope.user_id).filter(UserBlockScope.section_id == section_id).all()}
            users = [u for u in users if u.role != "BLOCK_ADMIN" or u.id in scoped_ids]
        for user in users:
            if exclude_user_id is not None and user.id == exclude_user_id:
                continue
            self._notify(user.id, title, message)

    def list(self, current_user, status=None):
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        return [self._response(x) for x in self.repo.list(current_user.organization_id, status, section_ids)]

    def update(self, current_user, incident_id, data):
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("You do not have permission to manage incidents.")
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        incident = self.repo.get_by_id(current_user.organization_id, incident_id, section_ids)
        if not incident:
            raise NotFoundException("Incident")
        if data.assigned_to_user_id is not None:
            self._org_user(current_user, data.assigned_to_user_id)
            incident.assigned_to_user_id = data.assigned_to_user_id
        if data.investigation_notes is not None:
            incident.investigation_notes = data.investigation_notes.strip()
        if data.resolution_notes is not None:
            incident.resolution_notes = data.resolution_notes.strip()
        if data.status:
            status = data.status.upper()
            if status == "RESOLVED":
                incident.resolved_at = datetime.utcnow()
            elif status in {"OPEN", "INVESTIGATING", "IN_PROGRESS"}:
                incident.resolved_at = None
            incident.status = status

        # Keep the reporter and assignee informed of lifecycle changes.
        # A resolved incident also creates an operational notification for the
        # rest of the organization's security/administration team.
        if data.status or data.investigation_notes is not None or data.resolution_notes is not None or data.assigned_to_user_id is not None:
            status_text = incident.status.replace("_", " ")
            detail = f"{incident.title} is now {status_text}."
            if incident.status == "RESOLVED" and incident.resolution_notes:
                detail += f" Resolution: {incident.resolution_notes}"
            self._notify(
                incident.created_by_user_id,
                f"Incident #{incident.id} Updated",
                detail,
            )
            if incident.assigned_to_user_id and incident.assigned_to_user_id != current_user.id:
                self._notify(
                    incident.assigned_to_user_id,
                    f"Incident #{incident.id} Updated",
                    detail,
                )
            if incident.status == "RESOLVED":
                self._notify_roles(
                    incident.organization_id,
                    {"ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "SECURITY_MANAGER", "SECURITY_GUARD", "BLOCK_ADMIN"},
                    f"Incident #{incident.id} Resolved",
                    f"{incident.title} has been resolved.",
                    exclude_user_id=current_user.id,
                    section_id=incident.section_id,
                )

        incident.updated_at = datetime.utcnow()
        self.repo.commit()
        logger.info("Incident updated id=%s status=%s", incident.id, incident.status)
        return self._response(incident)

    def add_evidence(self, current_user, incident_id, data):
        if current_user.role not in self.MANAGE_ROLES and current_user.role != "SECURITY_GUARD":
            raise ForbiddenException("You do not have permission to add incident evidence.")
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        incident = self.repo.get_by_id(current_user.organization_id, incident_id, section_ids)
        if not incident:
            raise NotFoundException("Incident")
        if data.evidence_type == "PHOTO" and not data.file_url:
            raise BadRequestException("Photo evidence requires a file URL.")
        evidence = IncidentEvidence(
            incident_id=incident.id,
            evidence_type=data.evidence_type,
            file_url=data.file_url,
            description=data.description,
            uploaded_by_user_id=current_user.id,
        )
        self.repo.create_evidence(evidence)
        self.repo.commit()
        return evidence

    async def add_photo(self, current_user, incident_id: int, upload):
        if current_user.role not in self.MANAGE_ROLES and current_user.role != "SECURITY_GUARD":
            raise ForbiddenException("You do not have permission to add incident evidence.")
        section_ids = None
        if current_user.role == "BLOCK_ADMIN":
            section_ids = ScopeService.block_ids(self.db, current_user)
        incident = self.repo.get_by_id(current_user.organization_id, incident_id, section_ids)
        if not incident:
            raise NotFoundException("Incident")
        content_type = upload.content_type or ""
        if not content_type.startswith("image/"):
            raise BadRequestException("Only image evidence is supported by this endpoint.")
        extension = Path(upload.filename or "").suffix.lower() or ".jpg"
        if extension not in {".jpg", ".jpeg", ".png", ".webp", ".gif"}:
            raise BadRequestException("Unsupported image format.")
        content = await upload.read()
        if len(content) > 10 * 1024 * 1024:
            raise BadRequestException("Incident photo must be 10 MB or smaller.")
        target_dir = Path("uploads/incidents")
        target_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{incident.id}-{uuid4().hex}{extension}"
        target = target_dir / filename
        target.write_bytes(content)
        evidence = IncidentEvidence(
            incident_id=incident.id,
            evidence_type="PHOTO",
            file_url=f"/uploads/incidents/{filename}",
            description=upload.filename,
            uploaded_by_user_id=current_user.id,
        )
        self.repo.create_evidence(evidence)
        self.repo.commit()
        return evidence

    def report(self, current_user):
        return self.repo.report(current_user.organization_id)
