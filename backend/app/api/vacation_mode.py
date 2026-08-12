from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.core.exceptions import ForbiddenException, NotFoundException
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.resident_repository import ResidentRepository
from app.repositories.vacation_repository import VacationRepository
from app.schemas.vacation_mode import (
    VacationModeCreate, VacationModeResponse,
    VacationSummaryResponse, ActiveVacationResponse,
)
from app.security.permissions import Permissions
from app.services.vacation_service import VacationService

router = APIRouter(prefix="/vacation-mode", tags=["Vacation Mode"])


def get_service(db: Session = Depends(get_db)) -> VacationService:
    return VacationService(VacationRepository(db))


@router.post(
    "",
    response_model=VacationModeResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission(Permissions.VACATION_CREATE))],
)
def enable_vacation(
    vacation: VacationModeCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: VacationService = Depends(get_service),
):
    resident = ResidentRepository(db).get_by_user_id(current_user.id)
    if resident is None:
        raise NotFoundException("Resident")
    return service.enable(resident.id, vacation)


@router.get(
    "/active",
    response_model=list[ActiveVacationResponse],
    dependencies=[Depends(require_permission(Permissions.VACATION_VIEW))],
)
def get_active_vacations(
    current_user: User = Depends(get_current_user),
    service: VacationService = Depends(get_service),
):
    if current_user.role not in {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "SECURITY_MANAGER", "SECURITY_GUARD"}:
        raise ForbiddenException("Only community/security staff can view all active vacations.")
    return service.get_active_vacations(current_user.organization_id)


@router.get(
    "/my-history",
    response_model=list[VacationModeResponse],
    dependencies=[Depends(require_permission(Permissions.VACATION_VIEW))],
)
def my_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: VacationService = Depends(get_service),
):
    resident = ResidentRepository(db).get_by_user_id(current_user.id)
    if resident is None:
        raise NotFoundException("Resident")
    return service.get_history(resident.id)


@router.get(
    "/resident/{resident_id}",
    response_model=list[VacationModeResponse],
    dependencies=[Depends(require_permission(Permissions.VACATION_VIEW))],
)
def get_vacation_history(
    resident_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: VacationService = Depends(get_service),
):
    resident = ResidentRepository(db).get_by_id(resident_id)
    if not resident:
        raise NotFoundException("Resident")
    if current_user.role == "RESIDENT" and resident.user_id != current_user.id:
        raise ForbiddenException("You can only view your own vacation history.")
    if current_user.role != "RESIDENT" and resident.user.organization_id != current_user.organization_id:
        raise ForbiddenException("Resident does not belong to your organization.")
    return service.get_history(resident_id)


@router.get(
    "/resident/{resident_id}/summary",
    response_model=VacationSummaryResponse,
    dependencies=[Depends(require_permission(Permissions.VACATION_VIEW))],
)
def get_vacation_summary(
    resident_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: VacationService = Depends(get_service),
):
    resident = ResidentRepository(db).get_by_id(resident_id)
    if not resident:
        raise NotFoundException("Resident")
    if current_user.role == "RESIDENT" and resident.user_id != current_user.id:
        raise ForbiddenException("You can only view your own vacation summary.")
    if current_user.role != "RESIDENT" and resident.user.organization_id != current_user.organization_id:
        raise ForbiddenException("Resident does not belong to your organization.")
    return service.get_summary(resident_id)


@router.put(
    "/{vacation_id}/cancel",
    response_model=VacationModeResponse,
    dependencies=[Depends(require_permission(Permissions.VACATION_CANCEL))],
)
def cancel_vacation(
    vacation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: VacationService = Depends(get_service),
):
    vacation = service.vacation_repo.get_by_id(vacation_id)
    if not vacation:
        raise NotFoundException("Vacation")
    resident = vacation.resident
    if current_user.role == "RESIDENT":
        if resident.user_id != current_user.id:
            raise ForbiddenException("You can only cancel your own vacation.")
    elif resident.user.organization_id != current_user.organization_id:
        raise ForbiddenException("Vacation does not belong to your organization.")
    return service.cancel(vacation_id)
