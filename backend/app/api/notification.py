from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.notification_repository import (
    NotificationRepository,
)

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


# =====================================================
# Dependency
# =====================================================

def get_notification_service(
    db: Session = Depends(get_db),
) -> NotificationService:

    repo = NotificationRepository(db)

    return NotificationService(repo)


# =====================================================
# Create Notification
# =====================================================

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
    service: NotificationService = Depends(
        get_notification_service,
    ),
):

    return service.create(notification)


# =====================================================
# Get Resident Notifications
# =====================================================

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
    service: NotificationService = Depends(
        get_notification_service,
    ),
):

    return service.get_by_resident(
        resident_id,
    )


# =====================================================
# Get Unread Notifications
# =====================================================

@router.get(
    "/resident/{resident_id}/unread",
    response_model=list[NotificationResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.NOTIFICATION_VIEW,
            )
        )
    ],
)
def unread_notifications(
    resident_id: int,
    service: NotificationService = Depends(
        get_notification_service,
    ),
):

    return service.repo.get_unread_by_user(
        resident_id,
    )


# =====================================================
# Get Unread Count
# =====================================================

@router.get(
    "/resident/{resident_id}/unread-count",
    dependencies=[
        Depends(
            require_permission(
                Permissions.NOTIFICATION_VIEW,
            )
        )
    ],
)
def unread_count(
    resident_id: int,
    service: NotificationService = Depends(
        get_notification_service,
    ),
):

    return service.unread_count(
        resident_id,
    )


# =====================================================
# Mark Single Notification As Read
# =====================================================

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
    service: NotificationService = Depends(
        get_notification_service,
    ),
):

    return service.mark_as_read(
        notification_id,
    )


# =====================================================
# Mark All Notifications As Read
# =====================================================

@router.put(
    "/resident/{resident_id}/read-all",
    dependencies=[
        Depends(
            require_permission(
                Permissions.NOTIFICATION_UPDATE,
            )
        )
    ],
)
def mark_all_read(
    resident_id: int,
    service: NotificationService = Depends(
        get_notification_service,
    ),
):

    return service.mark_all_as_read(
        resident_id,
    )