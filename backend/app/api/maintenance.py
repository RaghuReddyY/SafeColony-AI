from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.maintenance_repository import MaintenanceRepository
from app.schemas.maintenance import (
    MaintenanceDashboardResponse,
    MaintenanceExpenseCreate,
    MaintenanceExpenseResponse,
    MaintenancePeriodCreate,
    MaintenancePaymentCreate,
    MaintenancePeriodResponse,
    ResidentMaintenanceSummary,
    MaintenanceBillResponse,
)
from app.security.permissions import Permissions
from app.services.maintenance_service import MaintenanceService

router = APIRouter(prefix="/maintenance", tags=["Maintenance"])


def get_service(db: Session = Depends(get_db)) -> MaintenanceService:
    return MaintenanceService(MaintenanceRepository(db))


@router.get(
    "/dashboard",
    response_model=MaintenanceDashboardResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def dashboard(current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.dashboard(current_user)


@router.post(
    "/periods",
    response_model=MaintenancePeriodResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def create_period(data: MaintenancePeriodCreate, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    period = service.create_period(current_user, data)
    return service._period_response(period)


@router.post(
    "/periods/{period_id}/generate-bills",
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def generate_bills(period_id: int, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.generate_bills(current_user, period_id)


@router.post(
    "/periods/{period_id}/expenses",
    response_model=MaintenanceExpenseResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def add_expense(period_id: int, data: MaintenanceExpenseCreate, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.add_expense(current_user, period_id, data)


@router.get(
    "/me",
    response_model=ResidentMaintenanceSummary,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def my_maintenance(current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.resident_summary(current_user)


@router.post(
    "/bills/{bill_id}/payments",
    response_model=MaintenanceBillResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_PAYMENT))],
)
def record_payment(bill_id: int, data: MaintenancePaymentCreate, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.record_payment(current_user, bill_id, data)
