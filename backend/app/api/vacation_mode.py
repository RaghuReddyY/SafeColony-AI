from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.vacation_repository import VacationRepository
from app.schemas.vacation_mode import (
    VacationModeCreate,
    VacationModeResponse,
    VacationSummaryResponse,
    ActiveVacationResponse,
)
from app.services.vacation_service import VacationService
from app.auth.dependencies import get_current_user
from app.models.user import User
from app.repositories.resident_repository import ResidentRepository

router = APIRouter(
    prefix="/vacation-mode",
    tags=["Vacation Mode"],
)


def get_service(db: Session) -> VacationService:
    vacation_repo = VacationRepository(db)
    return VacationService(vacation_repo)


# ==========================================================
# Enable Vacation
# ==========================================================

@router.post(
    "",
    response_model=VacationModeResponse,
    status_code=status.HTTP_201_CREATED,
)
def enable_vacation(
    vacation: VacationModeCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

    print("========== VACATION ==========")
    print("Current User ID :", current_user.id)

    resident = ResidentRepository(db).get_by_user_id(current_user.id)

    print("Resident :", resident)

    if resident is None:
        raise HTTPException(
            status_code=404,
            detail="Resident profile not found.",
        )

    print("Resident ID :", resident.id)
    print("==============================")

    service = get_service(db)

    return service.enable(
        resident.id,
        vacation,
    )


# ==========================================================
# Active Vacations
# ==========================================================

@router.get(
    "/active",
    response_model=list[ActiveVacationResponse],
)
def get_active_vacations(
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.get_active_vacations()


# ==========================================================
# Vacation History
# ==========================================================

@router.get(
    "/resident/{resident_id}",
    response_model=list[VacationModeResponse],
)
def get_vacation_history(
    resident_id: int,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.get_history(resident_id)


# ==========================================================
# Vacation Summary
# ==========================================================

@router.get(
    "/resident/{resident_id}/summary",
    response_model=VacationSummaryResponse,
)
def get_vacation_summary(
    resident_id: int,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.get_summary(resident_id)


# ==========================================================
# Cancel Vacation
# ==========================================================

@router.put(
    "/{vacation_id}/cancel",
    response_model=VacationModeResponse,
)
def cancel_vacation(
    vacation_id: int,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.cancel(vacation_id)

@router.get(
    "/my-history",
    response_model=list[VacationModeResponse],
)
def my_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    resident = ResidentRepository(db).get_by_user_id(current_user.id)

    if resident is None:
        raise HTTPException(
            status_code=404,
            detail="Resident not found",
        )

    service = get_service(db)

    return service.get_history(resident.id)