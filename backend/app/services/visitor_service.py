from datetime import datetime

from app.core.logger import logger

from app.models.notification import Notification
from app.models.security_alert import SecurityAlert
from app.models.visitor import Visitor
from app.models.user import User

from app.repositories.notification_repository import (
    NotificationRepository,
)
from app.repositories.security_alert_repository import (
    SecurityAlertRepository,
)
from app.repositories.vacation_repository import (
    VacationRepository,
)
from app.repositories.resident_repository import (
    ResidentRepository,
)
from app.repositories.visitor_repository import (
    VisitorRepository,
)

from app.utils.qr_generator import QRGenerator

from app.enums.visitor_status import VisitorStatus
from app.enums.approval_mode import ApprovalMode
from app.enums.entry_mode import EntryMode

from app.core.exceptions import (
    BadRequestException,
    ForbiddenException,
    NotFoundException,
)

from app.schemas.visitor import (
    VisitorCreate,
    ResidentVisitorCreate,
)


class VisitorService:

    def __init__(
        self,
        repo: VisitorRepository,
        resident_repo: ResidentRepository | None = None,
    ):
        self.repo = repo
        self.resident_repo = resident_repo

    # ==================================================
    # Notification Helpers
    # ==================================================

    def _notify_resident(
        self,
        resident_id: int,
        title: str,
        message: str,
        notification_type: str = "VISITOR",
    ):
        """
        Create a notification for the resident's User account.

        Visitor.resident_id -> Resident.id
        Resident.user_id    -> User.id
        Notification.user_id -> User.id
        """

        resident_repo = self.resident_repo

        # If repository was not supplied, create one using
        # the same database session used by VisitorRepository.
        if resident_repo is None:
            resident_repo = ResidentRepository(
                self.repo.db
            )

        resident = resident_repo.get_by_id(
            resident_id
        )

        if resident is None:
            logger.warning(
                "Unable to send notification. "
                "Resident not found: %s",
                resident_id,
            )
            return None

        if resident.user_id is None:
            logger.warning(
                "Unable to send notification. "
                "Resident %s has no user account.",
                resident_id,
            )
            return None

        notification_repo = NotificationRepository(
            self.repo.db
        )

        notification = Notification(
            user_id=resident.user_id,
            title=title,
            message=message,
            notification_type=notification_type,
        )

        saved_notification = notification_repo.create(
            notification
        )

        logger.info(
            "Resident notification created | "
            "resident_id=%s | user_id=%s | "
            "type=%s | title=%s",
            resident_id,
            resident.user_id,
            notification_type,
            title,
        )

        return saved_notification

    # ==================================================
    # Common Visitor Creation
    # ==================================================

    def _create(
        self,
        resident_id: int,
        data,
        *,
        approval_mode: ApprovalMode,
        status: VisitorStatus,
        created_by_guard: bool,
    ):

        vacation_repo = VacationRepository(
            self.repo.db
        )

        vacation = vacation_repo.is_resident_on_vacation(
            resident_id
        )

        # --------------------------------------------------
        # Vacation Mode
        # --------------------------------------------------

        from app.enums.visitor_policy import VisitorPolicy

        if vacation:
            policy = vacation.visitor_policy
            blocked = policy == VisitorPolicy.REJECT_ALL.value
            pre_approved_only = (
                policy == VisitorPolicy.ALLOW_PRE_APPROVED.value
                and created_by_guard
            )

            if blocked or pre_approved_only:
                notification_repo = NotificationRepository(self.repo.db)
                resident_repo = self.resident_repo or ResidentRepository(self.repo.db)
                resident = resident_repo.get_by_id(resident_id)

                if resident and resident.user_id:
                    notification_repo.create(Notification(
                        user_id=resident.user_id,
                        title="Visitor Attempt Blocked",
                        message=(
                            f"Visitor {data.visitor_name} attempted to visit while "
                            f"Vacation Mode is active ({vacation.start_date} to {vacation.end_date})."
                        ),
                        notification_type="SECURITY",
                    ))

                SecurityAlertRepository(self.repo.db).create(SecurityAlert(
                    organization_id=(resident.user.organization_id if resident and resident.user else None),
                    resident_id=resident_id,
                    raised_by_user_id=(resident.user_id if resident else None),
                    source_role="RESIDENT",
                    title="Visitor Blocked",
                    message=(
                        f"Visitor {data.visitor_name} was blocked by Vacation Mode "
                        f"policy {vacation.visitor_policy}."
                    ),
                    alert_type="VISITOR",
                    severity="HIGH",
                ))

                raise ForbiddenException(
                    "Visitor is not allowed during the resident's current Vacation Mode."
                )

        # --------------------------------------------------
        # Create Visitor
        # --------------------------------------------------

        expected_time = (
            data.expected_time
            or datetime.utcnow()
        )

        visitor = Visitor(
            resident_id=resident_id,
            visitor_name=data.visitor_name,
            phone=data.phone,
            visitor_type=data.visitor_type,
            purpose=data.purpose,
            vehicle_number=data.vehicle_number,
            expected_time=expected_time,

            entry_mode=(
                EntryMode.WALK_IN.value
                if created_by_guard
                else data.entry_mode
            ),

            visitor_photo=data.visitor_photo,

            created_by_guard=created_by_guard,

            approval_mode=approval_mode.value,
            status=status.value,
        )

        saved_visitor = self.repo.create(
            visitor
        )

        # --------------------------------------------------
        # Generate QR for AUTO + QR
        # --------------------------------------------------

        if (
            approval_mode == ApprovalMode.AUTO
            and
            saved_visitor.entry_mode
            == EntryMode.QR.value
        ):
            token, qr_path = QRGenerator.generate(
                saved_visitor.id
            )

            saved_visitor.qr_token = token
            saved_visitor.qr_code = qr_path

            self.repo.save(
                saved_visitor
            )

        # --------------------------------------------------
        # IMPORTANT:
        # Guard Walk-In -> Resident Notification
        # --------------------------------------------------

        if created_by_guard:

            self._notify_resident(
                resident_id=resident_id,
                title="New Visitor Request",
                message=(
                    f"Guard has registered "
                    f"{saved_visitor.visitor_name} "
                    "as a walk-in visitor.\n\n"
                    "Please review and approve "
                    "or reject the visitor."
                ),
                notification_type="VISITOR",
                entity_type="VISITOR", entity_id=visitor.id, action="OPEN_VISITOR",
            )
            self._notify_admins(
                resident_id=resident_id,
                title="Walk-in Visitor Registered",
                message=(
                    f"Guard registered walk-in visitor {saved_visitor.visitor_name} "
                    f"for resident #{resident_id}. Waiting for resident approval."
                ),
            )

        logger.info(
            "%s Visitor created: %s (ID=%s)",
            saved_visitor.entry_mode,
            saved_visitor.visitor_name,
            saved_visitor.id,
        )

        return saved_visitor

    # ==================================================
    # Guard/Admin Flow
    # ==================================================

    def create(
        self,
        data: VisitorCreate,
    ):

        return self._create(
            resident_id=data.resident_id,
            data=data,
            approval_mode=ApprovalMode.RESIDENT,
            status=VisitorStatus.PENDING,
            created_by_guard=True,
        )

    # ==================================================
    # Resident Flow
    # ==================================================

    def create_for_resident(
        self,
        current_user: User,
        data: ResidentVisitorCreate,
    ):

        if self.resident_repo is None:
            raise BadRequestException(
                "Resident repository not configured."
            )

        resident = (
            self.resident_repo.get_by_user_id(
                current_user.id
            )
        )

        if resident is None:
            raise NotFoundException(
                "Resident"
            )

        visitor = self._create(
            resident_id=resident.id,
            data=data,
            approval_mode=ApprovalMode.AUTO,
            status=VisitorStatus.APPROVED,
            created_by_guard=False,
        )

        self._notify_guards(
            resident_id=resident.id,
            title="New Planned Visitor",
            message=(
                f"{visitor.visitor_name} has been registered by a resident "
                "and is approved for entry."
            ),
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=resident.id,
            title="Planned Visitor Created",
            message=f"{visitor.visitor_name} was registered by a resident and is approved for entry.",
        )

        return visitor

    # ==================================================
    # Queries
    # ==================================================

    def get_all(self):

        return self.repo.get_all()

    def get_by_resident(
        self,
        resident_id: int,
    ):

        return self.repo.get_by_resident(
            resident_id
        )

    def get_for_current_user(
        self,
        current_user: User,
    ):
        if self.resident_repo is None:
            raise BadRequestException(
                "Resident repository not configured."
            )

        resident = self.resident_repo.get_by_user_id(
            current_user.id
        )

        if resident is None:
            raise NotFoundException("Resident")

        return self.repo.get_by_resident(resident.id)

    # ==================================================
    # Approval
    # ==================================================

    def approve(
        self,
        visitor_id: int,
    ):

        visitor = self.repo.get_by_id(
            visitor_id
        )

        if visitor is None:
            raise NotFoundException(
                "Visitor"
            )

        return self._approve(
            visitor
        )

    def reject(
        self,
        visitor_id: int,
    ):

        visitor = self.repo.get_by_id(
            visitor_id
        )

        if visitor is None:
            raise NotFoundException(
                "Visitor"
            )

        visitor.status = (
            VisitorStatus.REJECTED.value
        )

        logger.info(
            "Visitor Rejected: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        # Notify resident about the state change.
        self._notify_resident(
            resident_id=visitor.resident_id,
            title="Visitor Rejected",
            message=(
                f"{visitor.visitor_name} "
                "has been rejected."
            ),
            notification_type="VISITOR",
        )

        return self.repo.save(
            visitor
        )

    # ==================================================
    # Manual Check-In
    # ==================================================

    def check_in(
        self,
        visitor_id: int,
    ):

        visitor = self.repo.get_by_id(
            visitor_id
        )

        if visitor is None:
            raise NotFoundException(
                "Visitor"
            )

        if (
            visitor.status
            != VisitorStatus.APPROVED.value
        ):
            raise BadRequestException(
                "Visitor must be approved before "
                "check-in."
            )

        visitor.status = (
            VisitorStatus.CHECKED_IN.value
        )

        visitor.check_in_time = (
            datetime.utcnow()
        )

        logger.info(
            "Visitor Checked-In: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        self._notify_resident(
            resident_id=visitor.resident_id,
            title="Visitor Checked In",
            message=(
                f"{visitor.visitor_name} "
                "has entered the colony."
            ),
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=visitor.resident_id,
            title="Visitor Checked In",
            message=f"{visitor.visitor_name} has entered the colony.",
        )

        return self.repo.save(
            visitor
        )

    # ==================================================
    # Manual Check-Out
    # ==================================================

    def check_out(
        self,
        visitor_id: int,
    ):

        visitor = self.repo.get_by_id(
            visitor_id
        )

        if visitor is None:
            raise NotFoundException(
                "Visitor"
            )

        if (
            visitor.status
            != VisitorStatus.CHECKED_IN.value
        ):
            raise BadRequestException(
                "Visitor is not checked in."
            )

        visitor.status = (
            VisitorStatus.CHECKED_OUT.value
        )

        visitor.check_out_time = (
            datetime.utcnow()
        )

        logger.info(
            "Visitor Checked-Out: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        self._notify_resident(
            resident_id=visitor.resident_id,
            title="Visitor Checked Out",
            message=(
                f"{visitor.visitor_name} "
                "has exited the colony."
            ),
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=visitor.resident_id,
            title="Visitor Checked Out",
            message=f"{visitor.visitor_name} has exited the colony.",
        )

        return self.repo.save(
            visitor
        )

    # ==================================================
    # QR Operations
    # ==================================================

    def validate_qr(
        self,
        qr_token: str,
    ):

        visitor = self.repo.get_by_qr_token(
            qr_token
        )

        if visitor is None:

            logger.warning(
                "Invalid QR code scanned: %s",
                qr_token,
            )

            raise NotFoundException(
                "Invalid QR Code"
            )

        return visitor

    def scan_qr(
        self,
        qr_token: str,
    ):

        visitor = self.repo.get_by_qr_token(
            qr_token
        )

        if visitor is None:

            logger.warning(
                "Invalid QR code scanned: %s",
                qr_token,
            )

            raise NotFoundException(
                "Invalid QR Code"
            )

        if (
            visitor.status
            != VisitorStatus.APPROVED.value
        ):
            raise BadRequestException(
                f"Visitor status is "
                f"{visitor.status}"
            )

        visitor.status = (
            VisitorStatus.CHECKED_IN.value
        )

        visitor.check_in_time = (
            datetime.utcnow()
        )

        self.repo.save(
            visitor
        )

        self._notify_resident(
            resident_id=visitor.resident_id,
            title="Visitor Checked In",
            message=(
                f"{visitor.visitor_name} "
                "has entered the colony."
            ),
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=visitor.resident_id,
            title="Visitor Checked In",
            message=f"{visitor.visitor_name} has entered the colony.",
        )

        logger.info(
            "QR Check-In: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        return visitor

    def scan_exit(
        self,
        qr_token: str,
    ):

        visitor = self.repo.get_by_qr_token(
            qr_token
        )

        if visitor is None:

            logger.warning(
                "Invalid QR code scanned: %s",
                qr_token,
            )

            raise NotFoundException(
                "Invalid QR Code"
            )

        if (
            visitor.status
            != VisitorStatus.CHECKED_IN.value
        ):
            raise BadRequestException(
                "Visitor is not checked in."
            )

        visitor.status = (
            VisitorStatus.CHECKED_OUT.value
        )

        visitor.check_out_time = (
            datetime.utcnow()
        )

        self.repo.save(
            visitor
        )

        self._notify_resident(
            resident_id=visitor.resident_id,
            title="Visitor Checked Out",
            message=(
                f"{visitor.visitor_name} "
                "has exited the colony."
            ),
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=visitor.resident_id,
            title="Visitor Checked Out",
            message=f"{visitor.visitor_name} has exited the colony.",
        )

        logger.info(
            "QR Check-Out: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        return visitor

    # ==================================================
    # Internal Approval
    # ==================================================

    def _approve(
        self,
        visitor: Visitor,
    ):

        if (
            visitor.approval_mode
            == ApprovalMode.AUTO.value
        ):
            raise BadRequestException(
                "Planned visitors are already approved."
            )

        if (
            visitor.status
            != VisitorStatus.PENDING.value
        ):
            raise BadRequestException(
                "Only pending visitors can be approved."
            )

        visitor.status = (
            VisitorStatus.APPROVED.value
        )

        visitor.approved_at = (
            datetime.utcnow()
        )

        if (
            visitor.entry_mode
            == EntryMode.QR.value
        ):
            token, qr_path = (
                QRGenerator.generate(
                    visitor.id
                )
            )

            visitor.qr_token = token
            visitor.qr_code = qr_path

        logger.info(
            "Visitor Approved: %s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        return self.repo.save(
            visitor
        )

    # ==================================================
    # Resident Approve
    # ==================================================

    def resident_approve(
        self,
        current_user: User,
        visitor_id: int,
    ):

        if self.resident_repo is None:
            raise BadRequestException(
                "Resident repository not configured."
            )

        resident = (
            self.resident_repo.get_by_user_id(
                current_user.id
            )
        )

        if resident is None:
            raise NotFoundException(
                "Resident"
            )

        visitor = self.repo.get_by_id(
            visitor_id
        )

        if visitor is None:
            raise NotFoundException(
                "Visitor"
            )

        if (
            visitor.resident_id
            != resident.id
        ):
            raise ForbiddenException(
                "You cannot approve another "
                "resident's visitor."
            )

        approved_visitor = self._approve(
                    visitor
                )

        self._notify_guards(
            resident_id=visitor.resident_id,
            title="Visitor Approved",
            message=(
                f"{visitor.visitor_name} has been approved by the resident "
                "and is ready for entry."
            ),
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=visitor.resident_id,
            title="Visitor Approved",
            message=f"{visitor.visitor_name} was approved by the resident and is ready for entry.",
        )

        return approved_visitor

    # ==================================================
    # Resident Reject
    # ==================================================

    def resident_reject(
        self,
        current_user: User,
        visitor_id: int,
    ):

        if self.resident_repo is None:
            raise BadRequestException(
                "Resident repository not configured."
            )

        resident = (
            self.resident_repo.get_by_user_id(
                current_user.id
            )
        )

        if resident is None:
            raise NotFoundException(
                "Resident"
            )

        visitor = self.repo.get_by_id(
            visitor_id
        )

        if visitor is None:
            raise NotFoundException(
                "Visitor"
            )

        if (
            visitor.resident_id
            != resident.id
        ):
            raise ForbiddenException(
                "You cannot reject another "
                "resident's visitor."
            )

        visitor.status = (
            VisitorStatus.REJECTED.value
        )

        logger.info(
            "Resident rejected visitor: "
            "%s (ID=%s)",
            visitor.visitor_name,
            visitor.id,
        )

        self.repo.save(
            visitor
        )

        self._notify_guards(
            resident_id=visitor.resident_id,
            title="Visitor Rejected",
            message=f"{visitor.visitor_name} has been rejected by the resident.",
            notification_type="VISITOR",
        )
        self._notify_admins(
            resident_id=visitor.resident_id,
            title="Visitor Rejected",
            message=f"{visitor.visitor_name} was rejected by the resident.",
        )

        return visitor

    def _notify_admins(
        self,
        resident_id: int,
        title: str,
        message: str,
        notification_type: str = "VISITOR",
    ):
        resident_repo = self.resident_repo or ResidentRepository(self.repo.db)
        resident = resident_repo.get_by_id(resident_id)
        if not resident or not resident.user or not resident.user.organization_id:
            return
        admins = (
            self.repo.db.query(User)
            .filter(
                User.organization_id == resident.user.organization_id,
                User.role == "ORGANIZATION_ADMIN",
                User.is_active.is_(True),
            )
            .all()
        )
        notification_repo = NotificationRepository(self.repo.db)
        for admin in admins:
            notification_repo.create(Notification(
                user_id=admin.id,
                title=title,
                message=message,
                notification_type=notification_type,
            ))

    # ==================================================
    # Pending Visitors For Resident
    # ==================================================

    def get_pending_for_resident(
        self,
        current_user: User,
    ):

        if self.resident_repo is None:
            raise BadRequestException(
                "Resident repository not configured."
            )

        resident = (
            self.resident_repo.get_by_user_id(
                current_user.id
            )
        )

        if resident is None:
            raise NotFoundException(
                "Resident"
            )

        return (
            self.repo.get_pending_for_resident(
                resident.id
            )
        )

    # ==================================================
    # Guard Walk-In
    # ==================================================

    def create_walk_in(
        self,
        data: VisitorCreate,
    ):

        return self._create(
            resident_id=data.resident_id,
            data=data,
            approval_mode=ApprovalMode.RESIDENT,
            status=VisitorStatus.PENDING,
            created_by_guard=True,
        )

    def _notify_guards(
        self,
        resident_id: int,
        title: str,
        message: str,
        notification_type: str = "VISITOR",
    ):
        """
        Notify all active security guards belonging to
        the same organization as the resident.

        Visitor.resident_id -> Resident.id
        Resident.user_id    -> User.id
        Resident.user.organization_id -> Organization
        """

        resident_repo = (
            self.resident_repo
            or ResidentRepository(self.repo.db)
        )

        resident = resident_repo.get_by_id(
            resident_id
        )

        if resident is None:
            logger.warning(
                "Unable to notify guards. "
                "Resident not found: %s",
                resident_id,
            )
            return

        if resident.user is None:
            logger.warning(
                "Unable to notify guards. "
                "Resident user not found: %s",
                resident_id,
            )
            return

        organization_id = (
            resident.user.organization_id
        )

        if organization_id is None:
            logger.warning(
                "Unable to notify guards. "
                "Resident has no organization: %s",
                resident_id,
            )
            return

        guards = (
            self.repo.db.query(User)
            .filter(
                User.organization_id == organization_id,
                User.role == "SECURITY_GUARD",
                User.is_active.is_(True),
            )
            .all()
        )

        if not guards:
            logger.warning(
                "No active security guards found "
                "for organization=%s",
                organization_id,
            )
            return

        notification_repo = NotificationRepository(
            self.repo.db
        )

        for guard in guards:

            notification = Notification(
                user_id=guard.id,
                title=title,
                message=message,
                notification_type=notification_type,
            )

            notification_repo.create(
                notification
            )

            logger.info(
                "Guard notification created | "
                "guard_id=%s | resident_id=%s | "
                "type=%s | title=%s",
                guard.id,
                resident_id,
                notification_type,
                title,
            )