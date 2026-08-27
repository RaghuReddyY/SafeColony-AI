import random
from datetime import datetime

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.core.logger import logger
from app.enums.delivery_status import DeliveryStatus
from app.enums.delivery_policy import DeliveryPolicy
from app.enums.user_role import UserRole
from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.user import User
from app.repositories.delivery_repository import DeliveryRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.security_alert_repository import SecurityAlertRepository
from app.repositories.vacation_repository import VacationRepository
from app.repositories.resident_repository import ResidentRepository


class DeliveryService:
    def __init__(self, repo: DeliveryRepository):
        self.repo = repo

    def create(self, data):
        # Guard/admin registration means the package is physically being
        # declared at the gate for the selected resident. Notify that
        # resident. The authenticated-resident flow below intentionally does
        # not notify the resident about their own declaration.
        return self._create_for_resident(
            data.resident_id,
            data,
            notify_resident=True,
        )

    def create_for_resident(self, data, current_user: User):
        resident = ResidentRepository(self.repo.db).get_by_user_id(current_user.id)
        if resident is None:
            raise NotFoundException("Resident")
        return self._create_for_resident(
            resident.id,
            data,
            notify_resident=False,
        )

    def _resident_context(self, resident_id: int):
        resident = ResidentRepository(self.repo.db).get_by_id(resident_id)
        if resident is None:
            raise NotFoundException("Resident")
        if resident.user_id is None or resident.user is None:
            raise BadRequestException("Resident does not have a user account.")
        return resident

    def _notify_org(self, organization_id: int, roles: list[str], title: str, message: str):
        repo = NotificationRepository(self.repo.db)
        users = (
            self.repo.db.query(User)
            .filter(
                User.organization_id == organization_id,
                User.role.in_(roles),
                User.is_active.is_(True),
            )
            .all()
        )
        for user in users:
            repo.create(Notification(
                user_id=user.id,
                title=title,
                message=message,
                notification_type="DELIVERY",
            ))

    def _create_for_resident(
        self,
        resident_id: int,
        data,
        notify_resident: bool = False,
    ):
        resident = self._resident_context(resident_id)
        vacation = VacationRepository(self.repo.db).is_resident_on_vacation(resident_id)
        notification_repo = NotificationRepository(self.repo.db)
        alert_repo = SecurityAlertRepository(self.repo.db)

        policy = vacation.delivery_policy if vacation else DeliveryPolicy.ALLOW.value
        if vacation and policy == DeliveryPolicy.REJECT.value:
            message = (
                f"Courier {data.courier_name} attempted delivery while Vacation Mode is active "
                f"({vacation.start_date} to {vacation.end_date}); the delivery was rejected."
            )
            notification_repo.create(Notification(
                user_id=resident.user_id,
                title="Delivery Rejected",
                message=message,
                notification_type="DELIVERY",
            ))
            self._notify_org(resident.user.organization_id, [UserRole.ORGANIZATION_ADMIN.value, UserRole.SECURITY_GUARD.value], "Delivery Rejected", message)
            alert_repo.create(SecurityAlert(
                organization_id=resident.user.organization_id,
                resident_id=resident_id,
                raised_by_user_id=resident.user_id,
                source_role="RESIDENT",
                title="Delivery Rejected",
                message=message,
                alert_type="DELIVERY",
                severity="MEDIUM",
            ))
            raise ForbiddenException("Delivery is not allowed during Vacation Mode.")

        delivery = Delivery(
            resident_id=resident_id,
            courier_name=data.courier_name,
            tracking_number=data.tracking_number,
            delivery_category=data.delivery_category,
            package_photo=data.package_photo,
            priority=data.priority,
            otp=self._generate_otp(),
            status=DeliveryStatus.NOTIFIED.value,
        )
        saved = self.repo.create(delivery)

        if vacation and policy == DeliveryPolicy.KEEP_AT_GATE.value:
            title = "Delivery Kept At Gate"
            message = (
                f"Package from {saved.courier_name} is at the security gate and will be kept there "
                f"because Vacation Mode is active until {vacation.end_date}."
            )
        else:
            title = "Delivery Arrived"
            message = f"Package from {saved.courier_name} has arrived at the security gate."

        # A resident creating/declaring a delivery should not receive an
        # immediate "Delivery Arrived" alert for their own action. The
        # operational notification belongs to security/admin. The resident
        # will be notified later when the guard actually receives/collects it.
        if notify_resident and resident.user_id:
            NotificationRepository(self.repo.db).create(
                Notification(
                    user_id=resident.user_id,
                    title=title,
                    message=message,
                    notification_type="DELIVERY",
                )
            )

        self._notify_org(
            resident.user.organization_id,
            [UserRole.SECURITY_GUARD.value],
            title,
            message,
        )
        self._notify_org(
            resident.user.organization_id,
            [UserRole.ORGANIZATION_ADMIN.value],
            title,
            message,
        )
        logger.info("Delivery Created: %s for Resident=%s", saved.courier_name, saved.resident_id)
        return self.repo.save(saved)

    def get_all(self):
        return self.repo.get_all()

    def get_by_id(self, delivery_id: int):
        return self.repo.get_by_id(delivery_id)

    def get_by_resident(self, resident_id: int):
        return self.repo.get_by_resident(resident_id)

    def get_my_deliveries(self, current_user: User):
        resident = ResidentRepository(self.repo.db).get_by_user_id(current_user.id)
        if resident is None:
            raise NotFoundException("Resident")
        return self.repo.get_by_resident(resident.id)

    def receive(self, delivery_id: int, security_guard: str):
        delivery = self.repo.get_by_id(delivery_id)
        if delivery is None:
            raise NotFoundException("Delivery")
        if delivery.status in (DeliveryStatus.COLLECTED.value, DeliveryStatus.REJECTED.value):
            raise BadRequestException("Delivery cannot be received in its current state.")
        delivery.received_by = security_guard
        # Physical gate receipt is the point at which the package becomes
        # ARRIVED. Keep it pending until the resident provides the OTP.
        delivery.status = DeliveryStatus.ARRIVED.value
        resident = ResidentRepository(self.repo.db).get_by_id(delivery.resident_id)
        if resident and resident.user_id:
            NotificationRepository(self.repo.db).create(Notification(
                user_id=resident.user_id,
                title="Package Received By Guard",
                message=f"Package from {delivery.courier_name} was received by security guard {security_guard}.",
                notification_type="DELIVERY",
            ))
            self._notify_org(
                resident.user.organization_id,
                [UserRole.ORGANIZATION_ADMIN.value],
                "Package Received",
                f"Package from {delivery.courier_name} was received by guard {security_guard}.",
            )
        return self.repo.save(delivery)

    def verify_otp(self, delivery_id: int, otp: str):
        delivery = self.repo.get_by_id(delivery_id)
        if delivery is None:
            raise NotFoundException("Delivery")
        if delivery.status == DeliveryStatus.COLLECTED.value:
            raise BadRequestException("Delivery already collected.")
        if delivery.status == DeliveryStatus.REJECTED.value:
            raise BadRequestException("Rejected delivery cannot be collected.")
        if delivery.otp != otp:
            raise BadRequestException("Invalid OTP.")
        delivery.status = DeliveryStatus.COLLECTED.value
        delivery.collected_at = datetime.utcnow()
        resident = ResidentRepository(self.repo.db).get_by_id(delivery.resident_id)
        if resident and resident.user_id:
            NotificationRepository(self.repo.db).create(Notification(
                user_id=resident.user_id,
                title="Package Collected",
                message=f"Your package from {delivery.courier_name} has been collected.",
                notification_type="DELIVERY",
            ))
            self._notify_org(
                resident.user.organization_id,
                [UserRole.ORGANIZATION_ADMIN.value],
                "Package Collected",
                f"Package from {delivery.courier_name} was collected by the resident.",
            )
        return self.repo.save(delivery)

    def _generate_otp(self):
        return str(random.randint(100000, 999999))

    def pending_deliveries(self):
        return self.repo.pending_deliveries()
