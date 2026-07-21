import random
from datetime import datetime

from app.core.exceptions import (
    BadRequestException,
    NotFoundException,
)
from app.core.logger import logger

from app.enums.delivery_status import DeliveryStatus

from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.security_alert import SecurityAlert

from app.repositories.delivery_repository import DeliveryRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.security_alert_repository import (
    SecurityAlertRepository,
)
from app.repositories.vacation_repository import VacationRepository


class DeliveryService:

    def __init__(
        self,
        repo: DeliveryRepository,
    ):
        self.repo = repo

    # --------------------------------------------------
    # Create Delivery
    # --------------------------------------------------

    def create(self, data):

        vacation_repo = VacationRepository(self.repo.db)

        notification_repo = NotificationRepository(self.repo.db)

        alert_repo = SecurityAlertRepository(self.repo.db)

        vacation = vacation_repo.is_resident_on_vacation(
            data.resident_id
        )

        delivery = Delivery(
            resident_id=data.resident_id,
            courier_name=data.courier_name,
            tracking_number=data.tracking_number,
            delivery_category=data.delivery_category,
            package_photo=data.package_photo,
            priority=data.priority,
            otp=self._generate_otp(),
            status=DeliveryStatus.ARRIVED.value,
        )

        saved_delivery = self.repo.create(delivery)

        # ----------------------------------------
        # Vacation Mode
        # ----------------------------------------

        if vacation:

            if vacation.allow_deliveries:

                saved_delivery.status = DeliveryStatus.ARRIVED.value

                notification_repo.create(
                    Notification(
                        resident_id=data.resident_id,
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

                saved_delivery.status = DeliveryStatus.REJECTED.value

                notification_repo.create(
                    Notification(
                        resident_id=data.resident_id,
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
                        resident_id=data.resident_id,
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

        else:

            saved_delivery.status = DeliveryStatus.NOTIFIED.value

            notification_repo.create(
                Notification(
                    resident_id=data.resident_id,
                    title="Package Arrived",
                    message=(
                        f"Courier "
                        f"{saved_delivery.courier_name} "
                        "has arrived."
                    ),
                    notification_type="DELIVERY",
                )
            )

        logger.info(
            "Delivery Created: %s for Resident=%s",
            saved_delivery.courier_name,
            saved_delivery.resident_id,
        )

        return self.repo.save(saved_delivery)

    # --------------------------------------------------
    # Queries
    # --------------------------------------------------

    def get_all(self):
        return self.repo.get_all()

    def get_by_id(
        self,
        delivery_id: int,
    ):
        return self.repo.get_by_id(delivery_id)

    def get_by_resident(
        self,
        resident_id: int,
    ):
        return self.repo.get_by_resident(resident_id)

    # --------------------------------------------------
    # Guard Receives Delivery
    # --------------------------------------------------

    def receive(
        self,
        delivery_id: int,
        security_guard: str,
    ):

        delivery = self.repo.get_by_id(delivery_id)

        if delivery is None:
            raise NotFoundException("Delivery")

        delivery.received_by = security_guard
        delivery.status = DeliveryStatus.RECEIVED.value

        logger.info(
            "Delivery Received: ID=%s Guard=%s",
            delivery.id,
            security_guard,
        )

        return self.repo.save(delivery)

    # --------------------------------------------------
    # OTP Verification
    # --------------------------------------------------

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

            logger.warning(
                "Delivery already collected: ID=%s",
                delivery_id,
            )

            raise BadRequestException(
                "Delivery already collected."
            )

        if delivery.otp != otp:

            logger.warning(
                "Invalid OTP for Delivery=%s",
                delivery_id,
            )

            raise BadRequestException(
                "Invalid OTP."
            )

        delivery.status = DeliveryStatus.COLLECTED.value
        delivery.collected_at = datetime.utcnow()

        logger.info(
            "Delivery Collected: ID=%s Resident=%s",
            delivery.id,
            delivery.resident_id,
        )

        return self.repo.save(delivery)

    # --------------------------------------------------
    # Helpers
    # --------------------------------------------------

    def _generate_otp(self):

        return str(
            random.randint(
                100000,
                999999,
            )
        )
    
    def pending_deliveries(self):
        return self.repo.pending_deliveries()