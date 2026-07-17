from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.guard_dashboard_repository import (
    GuardDashboardRepository,
)

from app.services.guard_dashboard_service import (
    GuardDashboardService,
)

from app.schemas.guard_dashboard import (
    GuardDashboardResponse,
)

router = APIRouter(
    prefix="/guard-dashboard",
    tags=["Guard Dashboard"],
)


@router.get(
    "",
    response_model=GuardDashboardResponse,
)
def dashboard(
    db: Session = Depends(get_db),
):

    repo = GuardDashboardRepository(db)

    service = GuardDashboardService(repo)

    return service.dashboard()