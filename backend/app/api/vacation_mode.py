from fastapi import APIRouter, Depends, status
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


router = APIRouter(
    prefix="/vacation-mode",
    tags=["Vacation Mode"],
)


def get_service(db: Session) -> VacationService:
    """
    Creates VacationService with all required dependencies.
    """
    vacation_repo = VacationRepository(db)
    return VacationService(vacation_repo)


# ------------------------------------------------------------------
# Enable Vacation Mode
# ------------------------------------------------------------------
@router.post(
    "",
    response_model=VacationModeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Enable Vacation Mode",
    description="Create a new vacation schedule for a resident.",
)
def enable_vacation(
    vacation: VacationModeCreate,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.enable(vacation)


# ------------------------------------------------------------------
# Get Active Vacations
# ------------------------------------------------------------------
@router.get(
    "/active",
    response_model=list[ActiveVacationResponse],
    summary="Get Active Vacations",
    description="Returns all currently active vacations for guard dashboard.",
)
def get_active_vacations(
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.get_active_vacations()


# ------------------------------------------------------------------
# Vacation History
# ------------------------------------------------------------------
@router.get(
    "/resident/{resident_id}",
    response_model=list[VacationModeResponse],
    summary="Resident Vacation History",
    description="Returns complete vacation history for a resident.",
)
def get_vacation_history(
    resident_id: int,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.get_history(resident_id)


# ------------------------------------------------------------------
# Vacation Summary
# ------------------------------------------------------------------
@router.get(
    "/resident/{resident_id}/summary",
    response_model=VacationSummaryResponse,
    summary="Vacation Summary",
    description="Returns vacation statistics for a resident.",
)
def get_vacation_summary(
    resident_id: int,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.get_summary(resident_id)


# ------------------------------------------------------------------
# Cancel Vacation
# ------------------------------------------------------------------
@router.put(
    "/{vacation_id}/cancel",
    response_model=VacationModeResponse,
    summary="Cancel Vacation",
    description="Cancels a scheduled or active vacation.",
)
def cancel_vacation(
    vacation_id: int,
    db: Session = Depends(get_db),
):
    service = get_service(db)
    return service.cancel(vacation_id)