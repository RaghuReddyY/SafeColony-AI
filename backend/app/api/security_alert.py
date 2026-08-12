from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.security_alert_repository import SecurityAlertRepository
from app.schemas.security_alert import EmergencySOSCreate, SecurityAlertCreate, SecurityAlertResponse
from app.security.permissions import Permissions
from app.services.security_alert_service import SecurityAlertService

router = APIRouter(
    prefix="/security-alerts",
    tags=["Security Alerts"],
)


def get_service(db: Session = Depends(get_db)) -> SecurityAlertService:
    return SecurityAlertService(SecurityAlertRepository(db))


@router.post(
    "/emergency",
    response_model=SecurityAlertResponse,
    dependencies=[Depends(require_permission(Permissions.EMERGENCY_RAISE))],
)
def raise_emergency(
    data: EmergencySOSCreate,
    current_user: User = Depends(get_current_user),
    service: SecurityAlertService = Depends(get_service),
):
    return service.raise_sos(current_user, data)


@router.post(
    "",
    response_model=SecurityAlertResponse,
    dependencies=[Depends(require_permission(Permissions.SECURITY_ALERT_RAISE))],
)
def raise_security_alert(
    data: SecurityAlertCreate,
    current_user: User = Depends(get_current_user),
    service: SecurityAlertService = Depends(get_service),
):
    return service.raise_security_alert(current_user, data)


@router.get(
    "",
    response_model=list[SecurityAlertResponse],
    dependencies=[Depends(require_permission(Permissions.EMERGENCY_VIEW))],
)
def get_all_alerts(
    current_user: User = Depends(get_current_user),
    service: SecurityAlertService = Depends(get_service),
):
    return service.get_all(current_user)


@router.get(
    "/unresolved",
    response_model=list[SecurityAlertResponse],
    dependencies=[Depends(require_permission(Permissions.EMERGENCY_VIEW))],
)
def get_unresolved_alerts(
    current_user: User = Depends(get_current_user),
    service: SecurityAlertService = Depends(get_service),
):
    return service.get_unresolved(current_user)


@router.put(
    "/{alert_id}/resolve",
    response_model=SecurityAlertResponse,
    dependencies=[Depends(require_permission(Permissions.EMERGENCY_RESOLVE))],
)
def resolve_alert(
    alert_id: int,
    current_user: User = Depends(get_current_user),
    service: SecurityAlertService = Depends(get_service),
):
    return service.resolve(current_user, alert_id)
