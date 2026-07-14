from datetime import datetime

from fastapi import HTTPException

from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.security_alert import SecurityAlert

from app.repositories.notification_repository import (
    NotificationRepository,
)
from app.repositories.security_alert_repository import (
    SecurityAlertRepository,
)
from app.repositories.vacation_repository import (
    VacationRepository,
)


class DeliveryService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):

        vacation_repo = VacationRepository(self.repo.db)

        vacation = vacation_repo.is_resident_on_vacation(
            data.resident_id
        )

        delivery = Delivery(
            resident_id=data.resident_id,
            courier_name=data.courier_name,
            tracking_number=data.tracking_number,
            package_type=data.package_type,
        )

        saved_delivery = self.repo.create(delivery)

        notification_repo = NotificationRepository(
            self.repo.db
        )

        alert_repo = SecurityAlertRepository(
            self.repo.db
        )

        # -----------------------------
        # Resident is on Vacation
        # -----------------------------
        if vacation:

            if vacation.allow_deliveries:

                saved_delivery.status = "RECEIVED_AT_GATE"

                notification = Notification(
                    resident_id=data.resident_id,
                    title="Package Received",
                    message=(
                        f"Package from "
                        f"{saved_delivery.courier_name} "
                        "received at security gate."
                    ),
                    notification_type="DELIVERY",
                )

                notification_repo.create(notification)

            else:

                saved_delivery.status = "REJECTED"

                notification = Notification(
                    resident_id=data.resident_id,
                    title="Package Rejected",
                    message=(
                        f"Package from "
                        f"{saved_delivery.courier_name} "
                        "was rejected because "
                        "Vacation Mode does not allow deliveries."
                    ),
                    notification_type="DELIVERY",
                )

                notification_repo.create(notification)

                alert = SecurityAlert(
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

                alert_repo.create(alert)

        # -----------------------------
        # Resident is Home
        # -----------------------------
        else:

            saved_delivery.status = "ARRIVED"

            notification = Notification(
                resident_id=data.resident_id,
                title="Package Arrived",
                message=(
                    f"Courier "
                    f"{saved_delivery.courier_name} "
                    "has arrived."
                ),
                notification_type="DELIVERY",
            )

            notification_repo.create(notification)

        return self.repo.save(saved_delivery)

    def get_all(self):

        return self.repo.get_all()

    def get_by_resident(
        self,
        resident_id: int,
    ):

        return self.repo.get_by_resident(
            resident_id
        )

    def receive(
        self,
        delivery_id: int,
        security_guard: str,
    ):

        delivery = self.repo.get_by_id(
            delivery_id
        )

        if delivery is None:

            raise HTTPException(
                status_code=404,
                detail="Delivery not found",
            )

        delivery.status = "RECEIVED"

        delivery.received_by = security_guard

        delivery.delivered_at = datetime.utcnow()

        return self.repo.save(delivery)