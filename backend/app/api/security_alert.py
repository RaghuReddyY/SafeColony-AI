from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.security_alert_repository import (
    SecurityAlertRepository,
)

from app.schemas.security_alert import (
    SecurityAlertResponse,
)

from app.services.security_alert_service import (
    SecurityAlertService,
)

router = APIRouter(
    prefix="/security-alerts",
    tags=["Security Alerts"],
)


@router.get(
    "",
    response_model=list[SecurityAlertResponse],
)
def get_all_alerts(
    db: Session = Depends(get_db),
):

    repo = SecurityAlertRepository(db)

    service = SecurityAlertService(repo)

    return service.get_all()


@router.get(
    "/unresolved",
    response_model=list[SecurityAlertResponse],
)
def get_unresolved_alerts(
    db: Session = Depends(get_db),
):

    repo = SecurityAlertRepository(db)

    service = SecurityAlertService(repo)

    return service.get_unresolved()


@router.put(
    "/{alert_id}/resolve",
    response_model=SecurityAlertResponse,
)
def resolve_alert(
    alert_id: int,
    db: Session = Depends(get_db),
):

    repo = SecurityAlertRepository(db)

    service = SecurityAlertService(repo)

    return service.resolve(alert_id)