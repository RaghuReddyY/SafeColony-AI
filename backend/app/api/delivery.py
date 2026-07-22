from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.delivery_repository import (
    DeliveryRepository,
)

from app.schemas.delivery import (
    DeliveryCreate,
    DeliveryResponse,
    VerifyOtpRequest,
)

from app.security.permissions import Permissions

from app.services.delivery_service import (
    DeliveryService,
)

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
    return DeliveryService(
        DeliveryRepository(db),
    )


# --------------------------------------------------
# Create Delivery
# --------------------------------------------------

@router.post(
    "",
    response_model=DeliveryResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.DELIVERY_CREATE,
            )
        )
    ],
)
def create_delivery(
    delivery: DeliveryCreate,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.create(delivery)


# --------------------------------------------------
# Get All Deliveries
# --------------------------------------------------

@router.get(
    "",
    response_model=list[DeliveryResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.DELIVERY_VIEW,
            )
        )
    ],
)
def get_deliveries(
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.get_all()


# --------------------------------------------------
# Get Delivery By ID
# --------------------------------------------------

@router.get(
    "/{delivery_id}",
    response_model=DeliveryResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.DELIVERY_VIEW,
            )
        )
    ],
)
def get_delivery(
    delivery_id: int,
    service: DeliveryService = Depends(get_delivery_service),
):
    delivery = service.get_by_id(
        delivery_id,
    )

    if delivery is None:
        raise NotFoundException("Delivery")

    return delivery


# --------------------------------------------------
# Resident Deliveries
# --------------------------------------------------

@router.get(
    "/resident/{resident_id}",
    response_model=list[DeliveryResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.DELIVERY_VIEW,
            )
        )
    ],
)
def resident_deliveries(
    resident_id: int,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.get_by_resident(
        resident_id,
    )


# --------------------------------------------------
# Receive Delivery
# --------------------------------------------------

@router.put(
    "/{delivery_id}/receive",
    response_model=DeliveryResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.DELIVERY_RECEIVE,
            )
        )
    ],
)
def receive_delivery(
    delivery_id: int,
    security_guard: str,
    service: DeliveryService = Depends(get_delivery_service),
):
    return service.receive(
        delivery_id,
        security_guard,
    )


# --------------------------------------------------
# Verify OTP & Collect Delivery
# --------------------------------------------------

@router.post(
    "/{delivery_id}/verify-otp",
    response_model=DeliveryResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.DELIVERY_VERIFY,
            )
        )
    ],
)
def verify_otp(
    delivery_id: int,
    request: VerifyOtpRequest,
    service: DeliveryService = Depends(get_delivery_service),
):
    delivery = service.verify_otp(
        delivery_id,
        request.otp,
    )

    if delivery is None:
        raise BadRequestException("Invalid OTP")

    return delivery