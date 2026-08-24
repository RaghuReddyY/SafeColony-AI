from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.dashboard_repository import DashboardRepository
from app.schemas.dashboard_summary import DashboardSummaryResponse
from app.schemas.organization_finance import OrganizationFinanceSummaryResponse, MoneyTransactionResponse
from app.security.permissions import Permissions
from app.auth.permissions import require_permission
from app.services.organization_finance_service import OrganizationFinanceService
from app.services.dashboard_service import DashboardService

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"],
)


@router.get(
    "/summary",
    response_model=DashboardSummaryResponse,
)
def dashboard_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repo = DashboardRepository(db)
    service = DashboardService(repo)

    return service.get_summary(current_user.id)

@router.get(
    "/finance-summary",
    response_model=OrganizationFinanceSummaryResponse,
    dependencies=[Depends(require_permission(Permissions.DASHBOARD_VIEW))],
)
def organization_finance_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return OrganizationFinanceService(db).summary(current_user)


@router.get(
    "/money-details",
    response_model=list[MoneyTransactionResponse],
    dependencies=[Depends(require_permission(Permissions.DASHBOARD_VIEW))],
)
def organization_money_details(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return OrganizationFinanceService(db).money_details(current_user)
