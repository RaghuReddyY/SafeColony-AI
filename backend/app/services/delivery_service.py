import random
from datetime import datetime

from app.core.exceptions import (
    BadRequestException,
    NotFoundException,
)
from app.core.logger import logger

from app.enums.delivery_status import DeliveryStatus
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

    def __init__(
        self,
        repo: DeliveryRepository,
    ):
        self.repo = repo

    # ==================================================
    # Create Delivery - Admin / Guard selected resident
    # ==================================================

    def create(self, data):
        return self._create_for_resident(
            resident_id=data.resident_id,
            data=data,
        )

    # ==================================================
    # Create Delivery - Logged-in Resident
    # ==================================================

    def create_for_resident(
        self,
        data,
        current_user: User,
    ):
        resident_repo = ResidentRepository(self.repo.db)

        resident = resident_repo.get_by_user_id(
            current_user.id,
        )

        if resident is None:
            raise NotFoundException("Resident")

        return self._create_for_resident(
            resident_id=resident.id,
            data=data,
        )

    # ==================================================
    # Common Creation Logic
    # ==================================================

    def _create_for_resident(
        self,
        resident_id: int,
        data,
    ):
        vacation_repo = VacationRepository(self.repo.db)
        notification_repo = NotificationRepository(self.repo.db)
        alert_repo = SecurityAlertRepository(self.repo.db)
        resident_repo = ResidentRepository(self.repo.db)

        resident = resident_repo.get_by_id(resident_id)

        if resident is None:
            raise NotFoundException("Resident")

        if resident.user_id is None:
            raise BadRequestException(
                "Resident does not have a user account."
            )

        vacation = vacation_repo.is_resident_on_vacation(
            resident_id
        )

        delivery = Delivery(
            resident_id=resident_id,
            courier_name=data.courier_name,
            tracking_number=data.tracking_number,
            delivery_category=data.delivery_category,
            package_photo=data.package_photo,
            priority=data.priority,
            otp=self._generate_otp(),
            status=DeliveryStatus.ARRIVED.value,
        )

        saved_delivery = self.repo.create(delivery)

        # --------------------------------------------------
        # Vacation Mode
        # --------------------------------------------------

        if vacation:
            if vacation.allow_deliveries:
                saved_delivery.status = (
                    DeliveryStatus.ARRIVED.value
                )

                notification_repo.create(
                    Notification(
                        user_id=resident.user_id,
                        title="Package Received",
                        message=(
                            f"Package from "
                            f"{saved_delivery.courier_name} "
                            "received at security gate."
                        ),
                        notification_type="DELIVERY",
                    )
                )
            else:
                saved_delivery.status = (
                    DeliveryStatus.REJECTED.value
                )

                notification_repo.create(
                    Notification(
                        user_id=resident.user_id,
                        title="Package Rejected",
                        message=(
                            f"Package from "
                            f"{saved_delivery.courier_name} "
                            "was rejected because Vacation Mode "
                            "does not allow deliveries."
                        ),
                        notification_type="DELIVERY",
                    )
                )

                alert_repo.create(
                    SecurityAlert(
                        resident_id=resident_id,
                        title="Delivery Rejected",
                        message=(
                            f"Courier "
                            f"{saved_delivery.courier_name} "
                            "attempted delivery during Vacation Mode."
                        ),
                        alert_type="DELIVERY",
                        severity="MEDIUM",
                    )
                )

        # --------------------------------------------------
        # Normal Delivery
        # --------------------------------------------------

        else:
            saved_delivery.status = (
                DeliveryStatus.NOTIFIED.value
            )

            # --------------------------------------------------
            # Notify Security Guards
            # --------------------------------------------------
            #
            # The resident creates the delivery, but the
            # Security Guard is the intended recipient of the
            # delivery notification.
            #
            # Find the resident's user first so that we can
            # identify the organization.
            # --------------------------------------------------

            resident_user = (
                self.repo.db.query(User)
                .filter(
                    User.id == resident.user_id,
                )
                .first()
            )

            if resident_user is not None:
                guards = (
                    self.repo.db.query(User)
                    .filter(
                        User.organization_id
                        == resident_user.organization_id,
                        User.role
                        == UserRole.SECURITY_GUARD.value,
                        User.is_active.is_(True),
                    )
                    .all()
                )

                for guard in guards:
                    notification_repo.create(
                        Notification(
                            user_id=guard.id,
                            title="Delivery Arrived",
                            message=(
                                f"Courier "
                                f"{saved_delivery.courier_name} "
                                "has arrived."
                            ),
                            notification_type="DELIVERY",
                        )
                    )

                logger.info(
                    "Delivery notification sent to %s guard(s) "
                    "for organization=%s",
                    len(guards),
                    resident_user.organization_id,
                )
            else:
                logger.warning(
                    "Could not find User for Resident=%s. "
                    "Guard notification was not created.",
                    resident_id,
                )

        logger.info(
            "Delivery Created: %s for Resident=%s",
            saved_delivery.courier_name,
            saved_delivery.resident_id,
        )

        return self.repo.save(saved_delivery)

    # ==================================================
    # Queries
    # ==================================================

    def get_all(self):
        return self.repo.get_all()

    def get_by_id(self, delivery_id: int):
        return self.repo.get_by_id(delivery_id)

    def get_by_resident(self, resident_id: int):
        return self.repo.get_by_resident(resident_id)

    def get_my_deliveries(self, current_user: User):
        resident_repo = ResidentRepository(self.repo.db)

        resident = resident_repo.get_by_user_id(
            current_user.id,
        )

        if resident is None:
            raise NotFoundException("Resident")

        return self.repo.get_by_resident(resident.id)

    # ==================================================
    # Guard Receives Delivery
    # ==================================================

    def receive(
        self,
        delivery_id: int,
        security_guard: str,
    ):
        delivery = self.repo.get_by_id(delivery_id)

        if delivery is None:
            raise NotFoundException("Delivery")

        if delivery.status == DeliveryStatus.COLLECTED.value:
            raise BadRequestException(
                "Delivery is already collected."
            )

        delivery.received_by = security_guard

        logger.info(
            "Delivery Received: ID=%s Guard=%s",
            delivery.id,
            security_guard,
        )

        return self.repo.save(delivery)

    # ==================================================
    # OTP Verification / Collection
    # ==================================================

    def verify_otp(
        self,
        delivery_id: int,
        otp: str,
    ):
        delivery = self.repo.get_by_id(delivery_id)

        if delivery is None:
            logger.warning(
                "Delivery not found: ID=%s",
                delivery_id,
            )
            raise NotFoundException("Delivery")

        if delivery.status == DeliveryStatus.COLLECTED.value:
            raise BadRequestException(
                "Delivery already collected."
            )

        if delivery.status == DeliveryStatus.REJECTED.value:
            raise BadRequestException(
                "Rejected delivery cannot be collected."
            )

        if delivery.otp != otp:
            logger.warning(
                "Invalid OTP for Delivery=%s",
                delivery_id,
            )
            raise BadRequestException("Invalid OTP.")

        delivery.status = DeliveryStatus.COLLECTED.value
        delivery.collected_at = datetime.utcnow()

        logger.info(
            "Delivery Collected: ID=%s Resident=%s",
            delivery.id,
            delivery.resident_id,
        )

        return self.repo.save(delivery)

    # ==================================================
    # Helpers
    # ==================================================

    def _generate_otp(self):
        return str(random.randint(100000, 999999))

    def pending_deliveries(self):
        return self.repo.pending_deliveries()
