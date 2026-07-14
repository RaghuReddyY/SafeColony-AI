from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.security_dashboard_repository import (
    SecurityDashboardRepository,
)

from app.schemas.security_dashboard import (
    SecurityDashboardResponse,
)

from app.services.security_dashboard_service import (
    SecurityDashboardService,
)

router = APIRouter(
    prefix="/security",
    tags=["Security Dashboard"],
)


@router.get(
    "/dashboard",
    response_model=SecurityDashboardResponse,
)
def get_dashboard(
    db: Session = Depends(get_db),
):

    repo = SecurityDashboardRepository(db)

    service = SecurityDashboardService(repo)

    return service.get_dashboard()