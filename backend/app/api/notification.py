from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.notification_repository import NotificationRepository

from app.schemas.notification import (
    NotificationCreate,
    NotificationResponse,
)

from app.security.permissions import Permissions
from app.services.notification_service import NotificationService

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


def get_notification_service(
    db: Session = Depends(get_db),
) -> NotificationService:
    repo = NotificationRepository(db)
    return NotificationService(repo)


@router.post(
    "",
    response_model=NotificationResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.NOTIFICATION_CREATE,
            )
        )
    ],
)
def create_notification(
    notification: NotificationCreate,
    service: NotificationService = Depends(get_notification_service),
):
    return service.create(notification)


@router.get(
    "/resident/{resident_id}",
    response_model=list[NotificationResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.NOTIFICATION_VIEW,
            )
        )
    ],
)
def get_notifications(
    resident_id: int,
    service: NotificationService = Depends(get_notification_service),
):
    return service.get_by_resident(resident_id)


@router.put(
    "/{notification_id}/read",
    response_model=NotificationResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.NOTIFICATION_UPDATE,
            )
        )
    ],
)
def mark_as_read(
    notification_id: int,
    service: NotificationService = Depends(get_notification_service),
):
    return service.mark_as_read(notification_id)