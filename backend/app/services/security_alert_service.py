from datetime import datetime

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.user import User
from app.models.resident import Resident
from app.core.event_bus import event_bus
from app.events.security_alert_events import SecurityAlertRaisedEvent


class SecurityAlertService:
    """Business logic for security alerts and Emergency SOS."""

    ALLOWED_EMERGENCY_TYPES = {"MEDICAL", "FIRE", "POLICE", "GENERAL"}
    ALLOWED_SECURITY_TYPES = {"PANIC", "TAILGATING", "FORCED_ENTRY", "SUSPICIOUS_ACTIVITY", "GUARD_ALERT", "RESIDENT_ALERT"}
    ALLOWED_SEVERITIES = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
    NOTIFY_ROLES = {
        "ORGANIZATION_ADMIN",
        "PROPERTY_MANAGER",
        "SECURITY_MANAGER",
        "SECURITY_GUARD",
    }
    RESOLVE_ROLES = {
        "SYSTEM_ADMIN",
        "ORGANIZATION_ADMIN",
        "PROPERTY_MANAGER",
        "SECURITY_MANAGER",
        "SECURITY_GUARD",
    }

    def __init__(self, repo):
        self.repo = repo
        self.db = repo.db

    def _resident_for_user(self, user: User) -> Resident | None:
        return (
            self.db.query(Resident)
            .filter(Resident.user_id == user.id)
            .first()
        )

    def _response(self, alert: SecurityAlert) -> dict:
        resident = alert.resident
        unit_number = None
        if resident and resident.unit:
            unit_number = resident.unit.unit_number

        return {
            "id": alert.id,
            "organization_id": alert.organization_id,
            "resident_id": alert.resident_id,
            "raised_by_user_id": alert.raised_by_user_id,
            "raised_by_name": alert.raised_by.full_name if alert.raised_by else None,
            "source_role": alert.source_role,
            "unit_number": unit_number,
            "title": alert.title,
            "message": alert.message,
            "alert_type": alert.alert_type,
            "severity": alert.severity,
            "is_resolved": alert.is_resolved,
            "resolved_by_user_id": alert.resolved_by_user_id,
            "resolved_by_name": alert.resolved_by.full_name if alert.resolved_by else None,
            "resolved_at": alert.resolved_at,
            "created_at": alert.created_at,
        }

    def _notify_security_team(
        self,
        current_user: User,
        alert: SecurityAlert,
    ) -> None:
        users = (
            self.db.query(User)
            .filter(
                User.organization_id == current_user.organization_id,
                User.role.in_(self.NOTIFY_ROLES),
                User.is_active.is_(True),
            )
            .all()
        )

        location = ""
        if alert.resident and alert.resident.unit:
            location = f" Unit {alert.resident.unit.unit_number}."

        message = (
            f"{alert.alert_type} emergency raised by "
            f"{current_user.full_name}.{location} "
            f"{alert.message or 'Immediate assistance may be required.'}"
        )

        for user in users:
            self.db.add(
                Notification(
                    user_id=user.id,
                    title=f"Emergency SOS - {alert.alert_type}",
                    message=message,
                    notification_type="EMERGENCY",
                )
            )

    def raise_sos(self, current_user: User, data) -> dict:
        if not current_user.organization_id:
            raise ForbiddenException("Your account is not associated with an organization.")

        emergency_type = data.emergency_type.strip().upper()
        severity = data.severity.strip().upper()

        if emergency_type not in self.ALLOWED_EMERGENCY_TYPES:
            raise BadRequestException(
                "Emergency type must be MEDICAL, FIRE, POLICE or GENERAL."
            )

        if severity not in self.ALLOWED_SEVERITIES:
            raise BadRequestException(
                "Severity must be LOW, MEDIUM, HIGH or CRITICAL."
            )

        resident = None
        if current_user.role == "RESIDENT":
            resident = self._resident_for_user(current_user)
            if not resident:
                raise NotFoundException("Resident")

        message = (data.message or "").strip()
        if not message:
            message = f"{emergency_type.title()} emergency assistance requested."

        alert = SecurityAlert(
            organization_id=current_user.organization_id,
            resident_id=resident.id if resident else None,
            raised_by_user_id=current_user.id,
            title=f"Emergency SOS - {emergency_type}",
            message=message,
            alert_type=emergency_type,
            severity=severity,
            source_role=current_user.role,
            is_resolved=False,
        )
        self.repo.create(alert)
        self.db.flush()

        event_bus.publish(SecurityAlertRaisedEvent(
            alert_id=alert.id,
            organization_id=alert.organization_id,
            alert_type=alert.alert_type,
            severity=alert.severity,
            raised_by_user_id=current_user.id,
        ))

        self._notify_security_team(current_user, alert)
        self.repo.commit()

        return self._response(alert)

    def raise_security_alert(self, current_user: User, data) -> dict:
        if not current_user.organization_id:
            raise ForbiddenException("Your account is not associated with an organization.")
        alert_type = data.alert_type.strip().upper()
        severity = data.severity.strip().upper()
        if alert_type not in self.ALLOWED_SECURITY_TYPES:
            raise BadRequestException(
                "Alert type must be PANIC, TAILGATING, FORCED_ENTRY, "
                "SUSPICIOUS_ACTIVITY, GUARD_ALERT or RESIDENT_ALERT."
            )
        if severity not in self.ALLOWED_SEVERITIES:
            raise BadRequestException("Severity must be LOW, MEDIUM, HIGH or CRITICAL.")

        resident = None
        if current_user.role == "RESIDENT":
            resident = self._resident_for_user(current_user)
            if not resident:
                raise NotFoundException("Resident")

        message = (data.message or "").strip() or f"{alert_type.replace('_', ' ').title()} reported."
        alert = SecurityAlert(
            organization_id=current_user.organization_id,
            resident_id=resident.id if resident else None,
            raised_by_user_id=current_user.id,
            title=f"Security Alert - {alert_type.replace('_', ' ').title()}",
            message=message,
            alert_type=alert_type,
            severity=severity,
            source_role=current_user.role,
            is_resolved=False,
        )
        self.repo.create(alert)
        self.db.flush()
        event_bus.publish(SecurityAlertRaisedEvent(
            alert_id=alert.id,
            organization_id=alert.organization_id,
            alert_type=alert.alert_type,
            severity=alert.severity,
            raised_by_user_id=current_user.id,
        ))
        self._notify_security_team(current_user, alert)
        self.repo.commit()
        return self._response(alert)

    def get_all(self, current_user: User) -> list[dict]:
        return [
            self._response(alert)
            for alert in self.repo.get_all(current_user.organization_id)
        ]

    def get_unresolved(self, current_user: User) -> list[dict]:
        return [
            self._response(alert)
            for alert in self.repo.get_unresolved(current_user.organization_id)
        ]

    def resolve(self, current_user: User, alert_id: int) -> dict:
        if current_user.role not in self.RESOLVE_ROLES:
            raise ForbiddenException("You do not have permission to resolve emergency alerts.")

        organization_id = current_user.organization_id
        if current_user.role == "SYSTEM_ADMIN" and organization_id is None:
            # System admins may have no organization. Existing organization-scoped
            # alerts are intentionally not resolved without an organization context.
            raise ForbiddenException("Select an organization before resolving an alert.")

        alert = self.repo.get_by_id(alert_id, organization_id)
        if not alert:
            raise NotFoundException("Emergency alert")

        if alert.is_resolved:
            raise BadRequestException("This emergency alert is already resolved.")

        alert.is_resolved = True
        alert.resolved_by_user_id = current_user.id
        alert.resolved_at = datetime.utcnow()

        if alert.raised_by_user_id and alert.raised_by_user_id != current_user.id:
            self.db.add(
                Notification(
                    user_id=alert.raised_by_user_id,
                    title="Emergency SOS Resolved",
                    message=(
                        f"Your emergency SOS #{alert.id} was resolved by "
                        f"{current_user.full_name}."
                    ),
                    notification_type="EMERGENCY",
                )
            )

        self.repo.commit()
        return self._response(alert)
