from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.schemas.setup import (
    SetupRequest,
    SetupResponse,
    SetupStatusResponse,
)

from app.services.setup_service import SetupService


router = APIRouter(
    prefix="/setup",
    tags=["Platform Setup"],
)


@router.get(
    "/status",
    response_model=SetupStatusResponse,
)
def setup_status(
    db: Session = Depends(get_db),
):
    service = SetupService(db)

    return service.status()


@router.post(
    "",
    response_model=SetupResponse,
)
def initialize_platform(
    request: SetupRequest,
    db: Session = Depends(get_db),
):
    service = SetupService(db)

    return service.initialize(request)