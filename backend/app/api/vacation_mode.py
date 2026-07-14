from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.vacation_repository import VacationRepository

from app.schemas.vacation_mode import (
    VacationModeCreate,
    VacationModeResponse,
    ActiveVacationResponse,
)

from app.services.vacation_service import VacationService


router = APIRouter(
    prefix="/vacation-mode",
    tags=["Vacation Mode"],
)


# -----------------------------
# Enable Vacation
# -----------------------------
@router.post(
    "",
    response_model=VacationModeResponse,
)
def enable_vacation(
    vacation: VacationModeCreate,
    db: Session = Depends(get_db),
):

    vacation_repo = VacationRepository(db)

    service = VacationService(
        vacation_repo,
    )

    return service.enable(vacation)


# -----------------------------
# Active Vacations (Guard Dashboard)
# -----------------------------
@router.get(
    "/active",
    response_model=list[ActiveVacationResponse],
)
def active_vacations(
    db: Session = Depends(get_db),
):

    vacation_repo = VacationRepository(db)

    service = VacationService(
        vacation_repo,
    )

    return service.get_active_vacations()


# -----------------------------
# Vacation History
# -----------------------------
@router.get(
    "/resident/{resident_id}",
    response_model=list[VacationModeResponse],
)
def get_vacation_history(
    resident_id: int,
    db: Session = Depends(get_db),
):

    vacation_repo = VacationRepository(db)

    service = VacationService(
        vacation_repo,
    )

    return service.get_history(resident_id)


# -----------------------------
# Cancel Vacation
# -----------------------------
@router.put(
    "/{vacation_id}/cancel",
    response_model=VacationModeResponse,
)
def cancel_vacation(
    vacation_id: int,
    db: Session = Depends(get_db),
):

    vacation_repo = VacationRepository(db)

    service = VacationService(
        vacation_repo,
    )

    return service.cancel(vacation_id)