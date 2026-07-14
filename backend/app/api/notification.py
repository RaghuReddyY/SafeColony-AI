from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.notification_repository import NotificationRepository
from app.schemas.notification import (
    NotificationCreate,
    NotificationResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


@router.post(
    "",
    response_model=NotificationResponse,
)
def create_notification(
    notification: NotificationCreate,
    db: Session = Depends(get_db),
):

    repo = NotificationRepository(db)
    service = NotificationService(repo)

    return service.create(notification)


@router.get(
    "/resident/{resident_id}",
    response_model=list[NotificationResponse],
)
def get_notifications(
    resident_id: int,
    db: Session = Depends(get_db),
):

    repo = NotificationRepository(db)
    service = NotificationService(repo)

    return service.get_by_resident(resident_id)


@router.put(
    "/{notification_id}/read",
    response_model=NotificationResponse,
)
def mark_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
):

    repo = NotificationRepository(db)
    service = NotificationService(repo)

    return service.mark_as_read(notification_id)