from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.notification_repository import NotificationRepository
from app.schemas.notification import NotificationCreate, NotificationResponse
from app.schemas.notification_template import NotificationTemplateCreate, NotificationTemplateResponse, NotificationDeliveryResponse
from app.schemas.notification_device import NotificationDeviceRegister, NotificationDeviceResponse, NotificationDeviceUnregister
from app.security.permissions import Permissions
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def get_notification_service(db: Session = Depends(get_db)) -> NotificationService:
    return NotificationService(NotificationRepository(db))


@router.post("", response_model=NotificationResponse, dependencies=[Depends(require_permission(Permissions.NOTIFICATION_CREATE))])
def create_notification(
    notification: NotificationCreate,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.create(notification, current_user)


@router.get("/me", response_model=list[NotificationResponse], dependencies=[Depends(require_permission(Permissions.NOTIFICATION_VIEW))])
def get_my_notifications(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.get_by_user(current_user.id)


@router.get("/me/unread", response_model=list[NotificationResponse], dependencies=[Depends(require_permission(Permissions.NOTIFICATION_VIEW))])
def unread_my_notifications(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.repo.get_unread_by_user(current_user.id)


@router.get("/me/unread-count", dependencies=[Depends(require_permission(Permissions.NOTIFICATION_VIEW))])
def unread_count(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.unread_count(current_user.id)


# Backward-compatible resident endpoint. Organization/ownership checks are enforced.
@router.get("/resident/{resident_id}", response_model=list[NotificationResponse], dependencies=[Depends(require_permission(Permissions.NOTIFICATION_VIEW))])
def get_notifications(
    resident_id: int,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    from app.repositories.resident_repository import ResidentRepository
    resident = ResidentRepository(service.db).get_by_id(resident_id)
    if not resident or resident.user_id != current_user.id:
        from app.core.exceptions import ForbiddenException
        raise ForbiddenException("You can only view your own notifications.")
    return service.get_by_user(current_user.id)


@router.put("/{notification_id}/read", response_model=NotificationResponse, dependencies=[Depends(require_permission(Permissions.NOTIFICATION_UPDATE))])
def mark_as_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.mark_as_read(notification_id, current_user)


@router.put("/me/read-all", dependencies=[Depends(require_permission(Permissions.NOTIFICATION_UPDATE))])
def mark_all_read(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.mark_all_as_read(current_user.id, current_user)


@router.post("/devices", response_model=NotificationDeviceResponse, dependencies=[Depends(require_permission(Permissions.NOTIFICATION_UPDATE))])
def register_device(
    data: NotificationDeviceRegister,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.register_device(current_user, data)


@router.post("/devices/unregister", dependencies=[Depends(require_permission(Permissions.NOTIFICATION_UPDATE))])
def unregister_device(
    data: NotificationDeviceUnregister,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.unregister_device(current_user, data.token)


@router.get("/devices", response_model=list[NotificationDeviceResponse], dependencies=[Depends(require_permission(Permissions.NOTIFICATION_VIEW))])
def list_devices(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.list_devices(current_user)


@router.get("/templates", response_model=list[NotificationTemplateResponse], dependencies=[Depends(require_permission(Permissions.NOTIFICATION_VIEW))])
def list_templates(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.list_templates(current_user)


@router.post("/templates", response_model=NotificationTemplateResponse, dependencies=[Depends(require_permission(Permissions.NOTIFICATION_CREATE))])
def create_template(
    data: NotificationTemplateCreate,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    return service.create_template(current_user, data)


@router.post("/outbox/process", dependencies=[Depends(require_permission(Permissions.NOTIFICATION_UPDATE))])
def process_outbox(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
):
    if current_user.role not in {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER"}:
        from app.core.exceptions import ForbiddenException
        raise ForbiddenException("Only administrators can process notification deliveries.")
    return {"processed": service.process_pending_deliveries()}
