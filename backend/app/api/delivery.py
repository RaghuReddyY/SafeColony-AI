from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User

from app.repositories.delivery_repository import DeliveryRepository

from app.schemas.delivery import (
    DeliveryCreate,
    DeliveryResponse,
    GuardDeliveryResponse,
    ResidentDeliveryCreate,
    VerifyOtpRequest,
)

from app.security.permissions import Permissions
from app.services.delivery_service import DeliveryService

from app.core.exceptions import (
    BadRequestException,
    NotFoundException,
)


router = APIRouter(
    prefix="/deliveries",
    tags=["Deliveries"],
)


def get_delivery_service(
    db: Session = Depends(get_db),
) -> DeliveryService:
    return DeliveryService(DeliveryRepository(db))


@router.post(
    "",
    response_model=DeliveryResponse,
    dependencies=[Depends(require_permission(Permissions.DELIVERY_CREATE))],
)
def create_delivery(
    delivery: DeliveryCreate,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.create(delivery)


@router.post(
    "/resident",
    response_model=DeliveryResponse,
    dependencies=[Depends(require_permission(Permissions.DELIVERY_CREATE))],
)
def create_resident_delivery(
    delivery: ResidentDeliveryCreate,
    current_user: User = Depends(get_current_user),
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.create_for_resident(delivery, current_user)


@router.post(
    "/guard",
    response_model=GuardDeliveryResponse,
    dependencies=[Depends(require_permission(Permissions.GUARD_DELIVERY_CREATE))],
)
def create_guard_delivery(
    delivery: DeliveryCreate,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.create(delivery)


@router.get(
    "/mine",
    response_model=list[DeliveryResponse],
    dependencies=[Depends(require_permission(Permissions.DELIVERY_VIEW))],
)
def my_deliveries(
    current_user: User = Depends(get_current_user),
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.get_my_deliveries(current_user)


@router.get(
    "",
    response_model=list[DeliveryResponse],
    dependencies=[Depends(require_permission(Permissions.DELIVERY_VIEW))],
)
def get_deliveries(
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.get_all()


@router.get(
    "/{delivery_id}",
    response_model=DeliveryResponse,
    dependencies=[Depends(require_permission(Permissions.DELIVERY_VIEW))],
)
def get_delivery(
    delivery_id: int,
    service: DeliveryService = Depends(get_delivery_service),
):
    delivery = service.get_by_id(delivery_id)
    if delivery is None:
        raise NotFoundException("Delivery")
    return delivery


@router.get(
    "/resident/{resident_id}",
    response_model=list[DeliveryResponse],
    dependencies=[Depends(require_permission(Permissions.DELIVERY_VIEW))],
)
def resident_deliveries(
    resident_id: int,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.get_by_resident(resident_id)


@router.put(
    "/{delivery_id}/receive",
    response_model=GuardDeliveryResponse,
    dependencies=[Depends(require_permission(Permissions.GUARD_DELIVERY_RECEIVE))],
)
def receive_delivery(
    delivery_id: int,
    security_guard: str,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.receive(delivery_id, security_guard)


@router.post(
    "/{delivery_id}/verify-otp",
    response_model=GuardDeliveryResponse,
    dependencies=[Depends(require_permission(Permissions.GUARD_DELIVERY_VERIFY))],
)
def verify_otp(
    delivery_id: int,
    request: VerifyOtpRequest,
    service: DeliveryService = Depends(get_delivery_service),
):
    delivery = service.verify_otp(delivery_id, request.otp)
    if delivery is None:
        raise BadRequestException("Invalid OTP")
    return delivery
