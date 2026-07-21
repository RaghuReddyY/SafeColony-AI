from datetime import datetime
from app.core.logger import logger
from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.visitor import Visitor

from app.repositories.notification_repository import NotificationRepository
from app.repositories.security_alert_repository import SecurityAlertRepository
from app.repositories.vacation_repository import VacationRepository

from app.utils.qr_generator import QRGenerator
from app.enums.visitor_status import VisitorStatus
from app.enums.approval_mode import ApprovalMode
from app.enums.entry_mode import EntryMode
from app.core.exceptions import (
    BadRequestException,
    ForbiddenException,
    NotFoundException,
)
from app.repositories.visitor_repository import VisitorRepository
from app.schemas.visitor import VisitorCreate
class VisitorService:

    def __init__(self, repo: VisitorRepository):
        self.repo = repo

    def create(self, data: VisitorCreate):

        vacation_repo = VacationRepository(self.repo.db)

        vacation = vacation_repo.is_resident_on_vacation(
            data.resident_id
        )

        if vacation and not vacation.allow_visitors:

            # Resident Notification
            notification_repo = NotificationRepository(
                self.repo.db
            )

            notification = Notification(
                resident_id=data.resident_id,
                title="Visitor Attempt Blocked",
                message=(
                    f"Visitor {data.visitor_name} "
                    "attempted to visit while Vacation Mode was active."
                ),
                notification_type="SECURITY",
            )

            notification_repo.create(notification)

            # Guard Security Alert
            alert_repo = SecurityAlertRepository(
                self.repo.db
            )

            alert = SecurityAlert(
                resident_id=data.resident_id,
                title="Visitor Blocked",
                message=(
                    f"Visitor {data.visitor_name} attempted entry "
                    "while Vacation Mode was active."
                ),
                alert_type="VISITOR",
                severity="HIGH",
            )

            alert_repo.create(alert)

            logger.warning(
            "Visitor blocked due to Vacation Mode: %s (Resident ID=%s)",
            data.visitor_name,
            data.resident_id,
        )
            raise ForbiddenException(
                   "Resident is on Vacation Mode. Visitors are not allowed."
            )

        expected_time = data.expected_time or datetime.utcnow()

        visitor = Visitor(
            resident_id=data.resident_id,
            visitor_name=data.visitor_name,
            phone=data.phone,
            visitor_type=data.visitor_type,
            purpose=data.purpose,
            vehicle_number=data.vehicle_number,
            expected_time=expected_time,

            # Walk-in Support
            entry_mode=data.entry_mode,
            visitor_photo=data.visitor_photo,
            created_by_guard=data.created_by_guard,

            # Initial Status
            status=VisitorStatus.PENDING.value,
        )

        saved_visitor = self.repo.create(visitor)

        logger.info(
            f"{saved_visitor.entry_mode} Visitor created: "
            f"{saved_visitor.visitor_name} "
            f"(ID={saved_visitor.id})"
        )
        return saved_visitor

    def get_all(self):
        return self.repo.get_all()

    def get_by_resident(self, resident_id: int):
        return self.repo.get_by_resident(resident_id)

    def approve(self, visitor_id: int):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise NotFoundException("Visitor")

        if visitor.status != VisitorStatus.PENDING.value:
            raise BadRequestException(
                   "Only pending visitors can be approved."
                    )

        visitor.status = VisitorStatus.APPROVED.value
        visitor.approved_at = datetime.utcnow()
        visitor.approval_mode = ApprovalMode.RESIDENT.value

        if visitor.entry_mode == EntryMode.QR.value:
            token, qr_path = QRGenerator.generate(visitor.id)

            visitor.qr_token = token
            visitor.qr_code = qr_path

            logger.info(
            "Visitor Approved: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
            )

        return self.repo.save(visitor)

    def reject(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise NotFoundException("Visitor")

        visitor.status = VisitorStatus.REJECTED.value

        logger.info(
            "Visitor Rejected: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
            )
            
        return self.repo.save(visitor)

    def check_in(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise NotFoundException("Visitor")

        if visitor.status != VisitorStatus.APPROVED.value:
            raise BadRequestException(
               "Visitor must be approved before check-in."
            )

        visitor.status = VisitorStatus.CHECKED_IN.value
        visitor.check_in_time = datetime.utcnow()

        logger.info(
        "Visitor Checked-In: %s (ID=%s)",
        visitor.visitor_name,
        visitor.id,
        )

        return self.repo.save(visitor)

    def check_out(self, visitor_id):

        visitor = self.repo.get_by_id(visitor_id)

        if visitor is None:
            raise NotFoundException("Visitor")
        
        if visitor.status != VisitorStatus.CHECKED_IN.value:
            raise BadRequestException(
                   "Visitor is not checked in."
            )

        visitor.status = VisitorStatus.CHECKED_OUT.value
        visitor.check_out_time = datetime.utcnow()

        logger.info(
        "Visitor Checked-Out: %s (ID=%s)",
        visitor.visitor_name,
        visitor.id,
        )

        return self.repo.save(visitor)

    def scan_qr(self, qr_token: str):

        visitor = self.repo.get_by_qr_token(qr_token)

        if visitor is None:
            logger.warning(
            "Invalid QR code scanned: %s",
            qr_token,
            )
            raise NotFoundException("Invalid QR Code")

        if visitor.status != VisitorStatus.APPROVED.value:
            raise BadRequestException(
               f"Visitor status is {visitor.status}"
            )

        visitor.status = VisitorStatus.CHECKED_IN.value
        visitor.check_in_time = datetime.utcnow()

        self.repo.save(visitor)

        logger.info(
        "QR Check-In: %s (ID=%s)",
        visitor.visitor_name,
        visitor.id,
        )

        return visitor

    def scan_exit(self, qr_token: str):

        visitor = self.repo.get_by_qr_token(qr_token)

        if visitor is None:
            logger.warning(
                "Invalid QR code scanned: %s",
                qr_token,
            )
            raise NotFoundException("Invalid QR Code")

        if visitor.status != VisitorStatus.CHECKED_IN.value:
            raise BadRequestException(
               "Visitor is not checked in."
            )

        visitor.status = VisitorStatus.CHECKED_OUT.value
        visitor.check_out_time = datetime.utcnow()

        logger.info(
        "QR Check-Out: %s (ID=%s)",
        visitor.visitor_name,
        visitor.id,
    )
        return self.repo.save(visitor)
    
    def validate_qr(self, qr_token: str):

        visitor = self.repo.get_by_qr_token(qr_token)

        if visitor is None:
            logger.warning(
            "Invalid QR code scanned: %s",
            qr_token,
            )
            raise NotFoundException("Invalid QR Code")
            
        return visitor