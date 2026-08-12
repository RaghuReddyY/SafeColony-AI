from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.security_dashboard_repository import SecurityDashboardRepository
from app.schemas.security_dashboard import SecurityDashboardResponse
from app.security.permissions import Permissions
from app.services.security_dashboard_service import SecurityDashboardService

router = APIRouter(
    prefix="/security",
    tags=["Security Dashboard"],
)


@router.get(
    "/dashboard",
    response_model=SecurityDashboardResponse,
    dependencies=[Depends(require_permission(Permissions.EMERGENCY_VIEW))],
)
def get_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return SecurityDashboardService(
        SecurityDashboardRepository(db)
    ).get_dashboard(current_user.organization_id)
