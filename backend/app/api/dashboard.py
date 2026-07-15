from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.dashboard_repository import DashboardRepository
from app.schemas.dashboard_summary import DashboardSummaryResponse
from app.services.dashboard_service import DashboardService

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"],
)


@router.get(
    "/summary/{resident_id}",
    response_model=DashboardSummaryResponse,
)
def dashboard_summary(
    resident_id: int,
    db: Session = Depends(get_db),
):

    repo = DashboardRepository(db)

    service = DashboardService(repo)

    return service.get_summary(resident_id)