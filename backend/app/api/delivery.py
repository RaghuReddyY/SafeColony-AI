from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.delivery_repository import (
    DeliveryRepository,
)

from app.schemas.delivery import (
    DeliveryCreate,
    DeliveryResponse,
)

from app.services.delivery_service import (
    DeliveryService,
)

router = APIRouter(
    prefix="/deliveries",
    tags=["Deliveries"],
)


@router.post(
    "",
    response_model=DeliveryResponse,
)
def create_delivery(
    delivery: DeliveryCreate,
    db: Session = Depends(get_db),
):

    repo = DeliveryRepository(db)

    service = DeliveryService(repo)

    return service.create(delivery)


@router.get(
    "",
    response_model=list[DeliveryResponse],
)
def get_deliveries(
    db: Session = Depends(get_db),
):

    repo = DeliveryRepository(db)

    service = DeliveryService(repo)

    return service.get_all()


@router.get(
    "/resident/{resident_id}",
    response_model=list[DeliveryResponse],
)
def get_resident_deliveries(
    resident_id: int,
    db: Session = Depends(get_db),
):

    repo = DeliveryRepository(db)

    service = DeliveryService(repo)

    return service.get_by_resident(resident_id)


@router.put(
    "/{delivery_id}/receive",
    response_model=DeliveryResponse,
)
def receive_delivery(
    delivery_id: int,
    security_guard: str,
    db: Session = Depends(get_db),
):

    repo = DeliveryRepository(db)

    service = DeliveryService(repo)

    return service.receive(
        delivery_id,
        security_guard,
    )