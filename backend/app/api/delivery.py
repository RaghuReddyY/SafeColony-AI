from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.delivery_repository import (
    DeliveryRepository,
)

from app.schemas.delivery import (
    DeliveryCreate,
    DeliveryResponse,
    VerifyOtpRequest,
)

from app.services.delivery_service import (
    DeliveryService,
)

router = APIRouter(
    prefix="/deliveries",
    tags=["Deliveries"],
)


# --------------------------------------------------
# Create Delivery
# --------------------------------------------------

@router.post(
    "",
    response_model=DeliveryResponse,
)
def create_delivery(
    delivery: DeliveryCreate,
    db: Session = Depends(get_db),
):

    service = DeliveryService(
        DeliveryRepository(db),
    )

    return service.create(delivery)


# --------------------------------------------------
# Get All Deliveries
# --------------------------------------------------

@router.get(
    "",
    response_model=list[DeliveryResponse],
)
def get_deliveries(
    db: Session = Depends(get_db),
):

    service = DeliveryService(
        DeliveryRepository(db),
    )

    return service.get_all()


# --------------------------------------------------
# Get Delivery By ID
# --------------------------------------------------

@router.get(
    "/{delivery_id}",
    response_model=DeliveryResponse,
)
def get_delivery(
    delivery_id: int,
    db: Session = Depends(get_db),
):

    service = DeliveryService(
        DeliveryRepository(db),
    )

    delivery = service.get_by_id(
        delivery_id,
    )

    if delivery is None:

        raise HTTPException(
            status_code=404,
            detail="Delivery not found",
        )

    return delivery


# --------------------------------------------------
# Resident Deliveries
# --------------------------------------------------

@router.get(
    "/resident/{resident_id}",
    response_model=list[DeliveryResponse],
)
def resident_deliveries(
    resident_id: int,
    db: Session = Depends(get_db),
):

    service = DeliveryService(
        DeliveryRepository(db),
    )

    return service.get_by_resident(
        resident_id,
    )


# --------------------------------------------------
# Receive Delivery
# --------------------------------------------------

@router.put(
    "/{delivery_id}/receive",
    response_model=DeliveryResponse,
)
def receive_delivery(
    delivery_id: int,
    security_guard: str,
    db: Session = Depends(get_db),
):

    service = DeliveryService(
        DeliveryRepository(db),
    )

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
)
def verify_otp(
    delivery_id: int,
    request: VerifyOtpRequest,
    db: Session = Depends(get_db),
):

    service = DeliveryService(
        DeliveryRepository(db),
    )

    delivery = service.verify_otp(
        delivery_id,
        request.otp,
    )

    if delivery is None:

        raise HTTPException(
            status_code=400,
            detail="Invalid OTP",
        )

    return delivery