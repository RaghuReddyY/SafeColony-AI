from fastapi import APIRouter, Depends, Header, Request
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.maintenance_repository import MaintenanceRepository
from app.schemas.maintenance import (
    MaintenanceDashboardResponse,
    MaintenanceExpenseCreate,
    MaintenanceExpenseUpdate,
    MaintenanceExpenseResponse,
    MaintenancePeriodCreate,
    MaintenancePeriodUpdate,
    MaintenancePaymentCreate,
    MaintenancePeriodResponse,
    ResidentMaintenanceSummary,
    MaintenanceBillResponse,
    MaintenanceBillUpdate,
    MaintenancePaymentLinkResponse,
    MaintenancePaymentSettings,
    MaintenancePaymentSettingsUpdate,
    DirectUPIPaymentCreate,
    MaintenancePendingPaymentResponse,
    MaintenanceInvoiceResponse,
    MaintenancePayerUpdate,
    MaintenancePayerResponse,
    MaintenanceReceiptResponse,
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


@router.put(
    "/periods/{period_id}",
    response_model=MaintenancePeriodResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def update_period(
    period_id: int,
    data: MaintenancePeriodUpdate,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    period = service.update_period(current_user, period_id, data)
    return service._period_response(period)


@router.delete(
    "/periods/{period_id}",
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def delete_period(
    period_id: int,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.delete_period(current_user, period_id)


@router.post(
    "/periods/{period_id}/generate-bills",
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def generate_bills(period_id: int, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.generate_bills(current_user, period_id)


@router.post(
    "/periods/{period_id}/close",
    response_model=MaintenancePeriodResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def close_period(period_id: int, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.close_period(current_user, period_id)


@router.post(
    "/periods/{period_id}/expenses",
    response_model=MaintenanceExpenseResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def add_expense(period_id: int, data: MaintenanceExpenseCreate, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.add_expense(current_user, period_id, data)

@router.put(
    "/expenses/{expense_id}",
    response_model=MaintenanceExpenseResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def update_expense(
    expense_id: int,
    data: MaintenanceExpenseUpdate,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.update_expense(current_user, expense_id, data)


@router.get(
    "/me",
    response_model=ResidentMaintenanceSummary,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def my_maintenance(current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.resident_summary(current_user)

@router.get(
    "/me/payer",
    response_model=MaintenancePayerResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def my_maintenance_payer(
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.maintenance_payer(current_user)


@router.put(
    "/me/payer",
    response_model=MaintenancePayerResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_PAYMENT))],
)
def update_maintenance_payer(
    data: MaintenancePayerUpdate,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.set_maintenance_payer(current_user, data.resident_id)


@router.put(
    "/bills/{bill_id}",
    response_model=MaintenanceBillResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def update_bill(
    bill_id: int,
    data: MaintenanceBillUpdate,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.update_bill(current_user, bill_id, data)


@router.delete(
    "/bills/{bill_id}",
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def delete_bill(
    bill_id: int,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.delete_bill(current_user, bill_id)


@router.post(
    "/bills/{bill_id}/payments",
    response_model=MaintenanceBillResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def record_payment(bill_id: int, data: MaintenancePaymentCreate, current_user: User = Depends(get_current_user), service: MaintenanceService = Depends(get_service)):
    return service.record_payment(current_user, bill_id, data)


@router.get(
    "/community-finance",
    response_model=MaintenanceDashboardResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def community_finance(
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    # Residents are intentionally allowed to see the payment status of
    # primary households in their own section.  The service already scopes
    # resident requests to the resident's section.  Do not strip the bills
    # here; the resident UI uses them to show PAID/UNPAID/PARTIAL status.
    return service.community_finance(current_user)



@router.get(
    "/payment-settings",
    response_model=MaintenancePaymentSettings,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def get_payment_settings(
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.get_payment_settings(current_user)


@router.put(
    "/payment-settings",
    response_model=MaintenancePaymentSettings,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def update_payment_settings(
    data: MaintenancePaymentSettingsUpdate,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.update_payment_settings(current_user, data)


@router.post(
    "/bills/{bill_id}/direct-upi-payment",
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_PAYMENT))],
)
def submit_direct_upi_payment(
    bill_id: int,
    data: DirectUPIPaymentCreate,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.submit_direct_upi_payment(current_user, bill_id, data)


@router.get(
    "/payments/pending",
    response_model=list[MaintenancePendingPaymentResponse],
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def pending_payments(
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.get_pending_payments(current_user)


@router.post(
    "/payments/{payment_id}/verify",
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_MANAGE))],
)
def verify_direct_upi_payment(
    payment_id: int,
    approve: bool,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.verify_direct_upi_payment(current_user, payment_id, approve)

@router.post(
    "/bills/{bill_id}/pay",
    response_model=MaintenancePaymentLinkResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_PAYMENT))],
)
def create_online_payment(
    bill_id: int,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.create_payment_link(current_user, bill_id)


@router.get(
    "/bills/{bill_id}/invoice",
    response_model=MaintenanceInvoiceResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def get_invoice(
    bill_id: int,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.invoice(current_user, bill_id)


@router.get(
    "/payments/{payment_id}/receipt",
    response_model=MaintenanceReceiptResponse,
    dependencies=[Depends(require_permission(Permissions.MAINTENANCE_VIEW))],
)
def get_receipt(
    payment_id: int,
    current_user: User = Depends(get_current_user),
    service: MaintenanceService = Depends(get_service),
):
    return service.receipt(current_user, payment_id)


@router.post("/payments/razorpay/webhook")
async def razorpay_webhook(
    request: Request,
    x_razorpay_signature: str | None = Header(default=None),
    service: MaintenanceService = Depends(get_service),
):
    raw_body = await request.body()
    return service.handle_razorpay_webhook(raw_body, x_razorpay_signature)
