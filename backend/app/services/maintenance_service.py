from datetime import date, datetime
from decimal import Decimal

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.core.logger import logger

from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_expense import MaintenanceExpense
from app.models.maintenance_payment import MaintenancePayment
from app.models.maintenance_period import MaintenancePeriod
from app.models.notification import Notification
from app.models.organization import Organization
from app.core.event_bus import event_bus
from app.events.maintenance_events import MaintenancePaidEvent
from app.models.user import User

from app.repositories.maintenance_repository import MaintenanceRepository
from app.repositories.resident_repository import ResidentRepository
from app.services.scope_service import ScopeService
from app.models.section import Section


class MaintenanceService:

    def __init__(
        self,
        repo: MaintenanceRepository,
    ):
        self.repo = repo
        self.db = repo.db
        self.resident_repo = ResidentRepository(self.db)

    # ==========================================================
    # Helpers
    # ==========================================================

    def _scope_section_id(self, current_user: User, requested: int | None = None) -> int | None:
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if requested is not None and requested not in ids:
                raise ForbiddenException("You can manage maintenance only for your assigned blocks.")
            if requested is not None:
                return requested
            if len(ids) == 1:
                return ids[0]
            raise BadRequestException("Select a block before creating a maintenance period.")
        if requested is not None:
            section = self.db.query(Section).filter(Section.id == requested).first()
            if not section or section.property.organization_id != current_user.organization_id:
                raise ForbiddenException("Selected block does not belong to your community.")
        return requested

    def _active_residents(
        self,
        organization_id: int,
        section_id: int | None = None,
    ):
        residents = self.resident_repo.get_dropdown_by_organization(organization_id)
        # Maintenance is a unit-level obligation. The primary resident owns
        # the bill and receives the payment notifications. Family members
        # share the unit but must never get a duplicate maintenance bill.
        residents = [r for r in residents if r.is_primary]
        if section_id is None:
            return residents
        return [r for r in residents if r.unit and r.unit.section_id == section_id]

    def _get_current_resident(
        self,
        current_user: User,
    ):
        """
        Always resolve the resident from the authenticated user.

        IMPORTANT:
        Never use a resident_id supplied by the Flutter client
        to determine which resident's maintenance data is shown.
        """

        resident = self.resident_repo.get_by_user_id(
            current_user.id
        )

        if not resident:
            raise NotFoundException("Resident")

        return resident

    def _get_current_resident_bill(
        self,
        current_user: User,
        bill_id: int,
    ):
        """
        Security-sensitive helper.

        The bill is queried using BOTH:
            bill_id
            logged-in resident_id

        Therefore a resident cannot access another resident's bill
        by changing the bill_id in the request.
        """

        resident = self._get_current_resident(
            current_user
        )

        if not resident.is_primary:
            raise ForbiddenException(
                "Maintenance bills are managed by the primary resident of the unit."
            )

        bill = self.repo.get_bill_for_resident(
            bill_id=bill_id,
            resident_id=resident.id,
        )

        if not bill:
            raise NotFoundException(
                "Maintenance bill"
            )

        return bill

    def _previous_closing_balance(
        self,
        organization_id: int,
        section_id: int | None = None,
    ):
        previous = self.repo.get_latest_period(
            organization_id,
            section_id,
        )

        if not previous:
            return Decimal("0.00")

        return (
            Decimal(
                str(previous.opening_balance)
            )
            + self.repo.sum_bills(
                previous.id,
                MaintenanceBill.amount_paid,
            )
            - self.repo.sum_expenses(
                previous.id
            )
        )

    def _payment_balance(
        self,
        bill: MaintenanceBill,
    ) -> Decimal:
        return max(
            Decimal("0.00"),
            Decimal(
                str(bill.total_due)
            )
            - Decimal(
                str(bill.amount_paid)
            ),
        )

    def _apply_late_fee(self, bill: MaintenanceBill, organization: Organization) -> None:
        """Calculate late fee according to the organization's configured policy."""
        if bill.status == "PAID":
            return
        today = date.today()
        days_late = (today - bill.due_date).days - int(
            getattr(organization, "late_fee_grace_days", 0) or 0
        )
        if days_late <= 0:
            return
        fee_type = (getattr(organization, "late_fee_type", "NONE") or "NONE").upper()
        value = Decimal(str(getattr(organization, "late_fee_value", 0) or 0))
        base = Decimal(str(bill.amount))
        if fee_type == "FLAT":
            fee = value
        elif fee_type == "PERCENT_PER_MONTH":
            months = max(1, (days_late + 29) // 30)
            fee = base * value / Decimal("100") * Decimal(str(months))
        elif fee_type == "PER_DAY":
            fee = value * Decimal(str(days_late))
        else:
            fee = Decimal("0.00")
        fee = fee.quantize(Decimal("0.01"))
        if fee != Decimal(str(bill.late_fee)):
            bill.late_fee = fee
            bill.total_due = base + Decimal(str(bill.carried_forward)) + fee

    # ==========================================================
    # Maintenance Period
    # ==========================================================

    def create_period(
        self,
        current_user: User,
        data,
    ):
        section_id = self._scope_section_id(current_user, data.section_id)
        existing = self.repo.get_period_by_month(
            current_user.organization_id,
            data.month.replace(day=1),
            section_id,
        )

        if existing:
            raise ConflictException(
                "Maintenance period already exists for this month."
            )

        if data.due_date < data.month:
            raise BadRequestException(
                "Due date cannot be before the maintenance month."
            )

        opening = self._previous_closing_balance(
            current_user.organization_id,
            section_id,
        )

        period = MaintenancePeriod(
            organization_id=current_user.organization_id,
            section_id=section_id,
            month=data.month.replace(day=1),
            monthly_amount=data.monthly_amount,
            due_date=data.due_date,
            status="DRAFT",
            opening_balance=opening,
            notes=data.notes,
            created_by=current_user.id,
        )

        self.repo.create_period(period)
        self.repo.commit()

        return period

    # ==========================================================
    # Generate Bills
    # ==========================================================

    def generate_bills(
        self,
        current_user: User,
        period_id: int,
    ):
        section_id = None
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if len(ids) != 1:
                raise BadRequestException("A block administrator must have exactly one block for bill generation.")
            section_id = ids[0]
        period = self.repo.get_period(
            period_id,
            current_user.organization_id,
            section_id=section_id,
        )

        if not period:
            raise NotFoundException(
                "Maintenance period"
            )
        if period.status == "CLOSED":
            raise BadRequestException("This maintenance period is closed and cannot generate bills.")

        residents = self._active_residents(
            current_user.organization_id,
            period.section_id,
        )

        existing = {
            bill.resident_id
            for bill in self.repo.get_bills_for_period(
                period.id
            )
        }

        created = 0

        for resident in residents:

            if resident.id in existing:
                continue

            carried_forward = Decimal(
                str(
                    self.repo.outstanding_balance_before(
                        current_user.organization_id,
                        resident.id,
                        period.month,
                    )
                )
            )

            total_due = (
                Decimal(
                    str(period.monthly_amount)
                )
                + carried_forward
            )

            bill = MaintenanceBill(
                period_id=period.id,
                resident_id=resident.id,
                amount=period.monthly_amount,
                carried_forward=carried_forward,
                late_fee=Decimal("0.00"),
                total_due=total_due,
                amount_paid=Decimal("0.00"),
                due_date=period.due_date,
                status="UNPAID",
            )

            self.repo.create_bill(bill)

            self.db.flush()

            if resident.user_id:

                self.db.add(
                    Notification(
                        user_id=resident.user_id,
                        title="Maintenance Payment Due",
                        message=(
                            f"Your maintenance bill for "
                            f"{period.month.strftime('%B %Y')} "
                            f"is ₹{total_due:.2f}. "
                            f"Due date: "
                            f"{period.due_date.strftime('%d-%m-%Y')}."
                        ),
                        notification_type="MAINTENANCE_DUE",
                    )
                )

            created += 1

        if created > 0 or existing:
            period.status = "PUBLISHED"
            period.updated_at = datetime.utcnow()

        self.repo.commit()

        return {
            "created": created,
            "skipped": len(existing),
        }

    def close_period(self, current_user: User, period_id: int):
        section_id = None
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if len(ids) != 1:
                raise BadRequestException("A block administrator must have exactly one block to close a maintenance period.")
            section_id = ids[0]
        period = self.repo.get_period(period_id, current_user.organization_id, section_id=section_id)
        if not period:
            raise NotFoundException("Maintenance period")
        if period.status == "CLOSED":
            return self._period_response(period)
        period.status = "CLOSED"
        period.updated_at = datetime.utcnow()
        self.repo.commit()
        return self._period_response(period)

    # ==========================================================
    # Expenses
    # ==========================================================

    def add_expense(
        self,
        current_user: User,
        period_id: int,
        data,
    ):
        section_id = None
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if len(ids) != 1:
                raise BadRequestException("A block administrator must have exactly one block for expenses.")
            section_id = ids[0]
        period = self.repo.get_period(
            period_id,
            current_user.organization_id,
            section_id=section_id,
        )

        if not period:
            raise NotFoundException(
                "Maintenance period"
            )

        expense = MaintenanceExpense(
            period_id=period.id,
            category=data.category,
            description=data.description,
            amount=data.amount,
            spent_on=data.spent_on,
            created_by=current_user.id,
        )

        self.repo.create_expense(expense)
        self.repo.commit()

        return expense

    # ==========================================================
    # Bill Response
    # ==========================================================

    def _bill_response(
        self,
        bill: MaintenanceBill,
    ):
        resident = bill.resident

        return {
            "id": bill.id,
            "period_id": bill.period_id,
            "resident_id": bill.resident_id,
            "resident_name": (
                resident.full_name
                or "Resident"
            ),
            "property_name": resident.property_name,
            "section_name": resident.section_name,
            "unit_number": resident.unit_number,
            "amount": bill.amount,
            "carried_forward": bill.carried_forward,
            "late_fee": bill.late_fee,
            "total_due": bill.total_due,
            "amount_paid": bill.amount_paid,
            "balance": self._payment_balance(bill),
            "due_date": bill.due_date,
            "status": bill.status,
            "paid_at": bill.paid_at,
        }

    # ==========================================================
    # Period Response
    # ==========================================================

    def _period_response(
        self,
        period: MaintenancePeriod,
    ):
        billed = self.repo.sum_bills(
            period.id,
            MaintenanceBill.total_due,
        )

        collected = self.repo.sum_bills(
            period.id,
            MaintenanceBill.amount_paid,
        )

        expenses = self.repo.sum_expenses(
            period.id
        )

        closing = (
            Decimal(
                str(period.opening_balance)
            )
            + Decimal(str(collected))
            - Decimal(str(expenses))
        )

        return {
            "id": period.id,
            "organization_id": period.organization_id,
            "section_id": period.section_id,
            "month": period.month,
            "monthly_amount": period.monthly_amount,
            "due_date": period.due_date,
            "status": period.status,
            "opening_balance": period.opening_balance,
            "billed_total": billed,
            "collected_total": collected,
            "expense_total": expenses,
            "closing_balance": closing,
            "total_bills": self.repo.count_bills(
                period.id
            ),
            "paid_bills": self.repo.count_bills(
                period.id,
                "PAID",
            ),
            "unpaid_bills": (
                self.repo.count_bills(
                    period.id,
                    "UNPAID",
                )
                + self.repo.count_bills(
                    period.id,
                    "PARTIAL",
                )
            ),
            "notes": period.notes,
        }

    # ==========================================================
    # Admin Dashboard
    # ==========================================================

    def dashboard(
        self,
        current_user: User,
    ):
        section_id = None
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            section_id = ids[0] if len(ids) == 1 else None
        period = self.repo.get_latest_period(
            current_user.organization_id,
            section_id,
        )

        if not period:
            return {
                "period": None,
                "bills": [],
                "expenses": [],
            }

        bills = self.repo.get_bills_for_period(period.id)
        organization = self.db.query(Organization).filter(
            Organization.id == current_user.organization_id
        ).first()
        if organization:
            for bill in bills:
                self._apply_late_fee(bill, organization)
            self.repo.commit()

        return {
            "period": self._period_response(
                period
            ),
            "bills": [
                self._bill_response(bill)
                for bill in bills
            ],
            "expenses": self.repo.get_expenses_for_period(
                period.id
            ),
        }

    # ==========================================================
    # Resident Maintenance
    # ==========================================================

    def resident_summary(
        self,
        current_user: User,
    ):
        """
        CRITICAL RESIDENT ISOLATION.

        Find resident using authenticated user_id,
        then fetch bills using that resident_id only.
        """

        resident = self._get_current_resident(
            current_user
        )

        if not resident.is_primary:
            return {"bill": None, "history": [], "is_primary": False}

        bills = self.repo.get_bills_for_resident(
            resident.id
        )

        organization = self.db.query(Organization).filter(
            Organization.id == current_user.organization_id
        ).first()
        if organization:
            for bill in bills:
                self._apply_late_fee(bill, organization)
            self.repo.commit()

        return {
            "bill": (
                self._bill_response(bills[0])
                if bills
                else None
            ),
            "history": [
                self._bill_response(bill)
                for bill in bills
            ],
            "is_primary": True,
        }

    # ==========================================================
    # Community Finance
    # ==========================================================

    def community_finance(
        self,
        current_user: User,
    ):
        """
        Maintenance visibility for the finance/maintenance view.

        For residents, bills are scoped to the resident's own section and
        include the primary household payment status for that section.
        Organization/block administrators can see the appropriate scoped
        maintenance data for their role.
        """

        section_id = None
        if current_user.role == "RESIDENT":
            resident = self._get_current_resident(current_user)
            if resident.unit:
                section_id = resident.unit.section_id

        period = self.repo.get_latest_period(
            current_user.organization_id,
            section_id,
        )

        if not period:
            return {
                "period": None,
                "bills": [],
                "expenses": [],
            }

        if section_id is not None:
            bills = self.repo.get_bills_for_section(period.id, section_id)
        else:
            bills = self.repo.get_bills_for_period(period.id)

        return {
            "period": self._period_response(period),
            "bills": [self._bill_response(bill) for bill in bills],
            "expenses": self.repo.get_expenses_for_period(period.id),
        }

    # ==========================================================
    # Payment Settings
    # ==========================================================

    def get_payment_settings(
        self,
        current_user: User,
    ):
        organization = (
            self.db.query(Organization)
            .filter(
                Organization.id
                == current_user.organization_id
            )
            .first()
        )

        if not organization:
            raise NotFoundException(
                "Organization"
            )

        return {
            "mode": (
                organization.payment_mode
                or "RAZORPAY"
            ),
            "upi_id": organization.payment_upi_id,
            "display_name": organization.payment_display_name,
            "payment_phone": organization.payment_phone,
            "late_fee_type": organization.late_fee_type or "NONE",
            "late_fee_value": organization.late_fee_value or Decimal("0.00"),
            "late_fee_grace_days": organization.late_fee_grace_days or 0,
        }

    def update_payment_settings(
        self,
        current_user: User,
        data,
    ):
        if current_user.role not in {
            "SYSTEM_ADMIN",
            "ORGANIZATION_ADMIN",
            "BLOCK_ADMIN",
        }:
            raise ForbiddenException(
                "Only organization, system, or block administrators can update maintenance payment settings."
            )

        organization = (
            self.db.query(Organization)
            .filter(
                Organization.id
                == current_user.organization_id
            )
            .first()
        )

        if not organization:
            raise NotFoundException(
                "Organization"
            )

        mode = data.mode.upper()

        if mode not in {
            "RAZORPAY",
            "DIRECT_UPI",
        }:
            raise BadRequestException(
                "Payment mode must be RAZORPAY or DIRECT_UPI."
            )

        if mode == "DIRECT_UPI":

            if (
                not data.upi_id
                or "@" not in data.upi_id
            ):
                raise BadRequestException(
                    "Enter a valid UPI ID for Direct UPI mode."
                )

            if not data.display_name:
                raise BadRequestException(
                    "Enter the name residents should see for Direct UPI payments."
                )

        organization.payment_mode = mode

        organization.payment_upi_id = (
            data.upi_id.strip()
            if data.upi_id
            else None
        )

        organization.payment_display_name = (
            data.display_name.strip()
            if data.display_name
            else None
        )

        organization.payment_phone = (
            data.payment_phone.strip()
            if data.payment_phone
            else None
        )
        organization.late_fee_type = data.late_fee_type.upper()
        organization.late_fee_value = data.late_fee_value
        organization.late_fee_grace_days = data.late_fee_grace_days

        self.repo.commit()

        return self.get_payment_settings(
            current_user
        )

    # ==========================================================
    # Create Payment Link
    # ==========================================================

    def create_payment_link(
        self,
        current_user: User,
        bill_id: int,
    ):
        """
        Create payment instructions ONLY for the
        authenticated resident's own bill.
        """

        import base64
        import json
        import time
        import urllib.error
        import urllib.request

        # ------------------------------------------------------
        # IMPORTANT SECURITY FIX
        # ------------------------------------------------------

        bill = self._get_current_resident_bill(
            current_user,
            bill_id,
        )

        balance = self._payment_balance(
            bill
        )

        if balance <= 0:
            raise BadRequestException(
                "Maintenance bill is already paid."
            )

        organization = (
            self.db.query(Organization)
            .filter(
                Organization.id
                == current_user.organization_id
            )
            .first()
        )

        if not organization:
            raise NotFoundException(
                "Organization"
            )

        mode = (
            organization.payment_mode
            or "RAZORPAY"
        ).upper()

        # ======================================================
        # DIRECT UPI
        # ======================================================

        if mode == "DIRECT_UPI":

            if (
                not organization.payment_upi_id
                or not organization.payment_display_name
            ):
                raise BadRequestException(
                    "Direct UPI payment is not configured by the administrator."
                )

            reference_id = (
                f"SAFE-UPI-{bill.id}-{int(time.time())}"
            )

            from urllib.parse import quote

            upi_url = (
                "upi://pay?"
                f"pa={quote(organization.payment_upi_id)}"
                f"&pn={quote(organization.payment_display_name)}"
                f"&am={quote(f'{balance:.2f}')}"
                "&cu=INR"
                f"&tn={quote(f'SafeColony maintenance bill #{bill.id}')}"
            )

            return {
                "bill_id": bill.id,
                "amount": balance,
                "mode": "DIRECT_UPI",
                "reference_id": reference_id,
                "payment_link_id": None,
                "payment_url": upi_url,
                "expires_at": None,
                "upi_id": organization.payment_upi_id,
                "display_name": organization.payment_display_name,
                "payment_phone": organization.payment_phone,
                "message": (
                    "Pay using PhonePe, Google Pay or another "
                    "UPI app. After payment, submit the UPI "
                    "transaction reference. An administrator "
                    "will verify it before the bill becomes PAID."
                ),
            }

        # ======================================================
        # RAZORPAY
        # ======================================================

        from app.config import settings

        if (
            not settings.RAZORPAY_KEY_ID
            or not settings.RAZORPAY_KEY_SECRET
        ):
            raise BadRequestException(
                "Razorpay online payment is not configured. "
                "Add RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET "
                "to the backend environment, or switch the "
                "community to Direct UPI in Payment Settings."
            )

        reference_id = (
            f"SAFE-MAINT-{bill.id}-{int(time.time())}"
        )

        expire_by = (
            int(time.time())
            + (
                settings.RAZORPAY_PAYMENT_LINK_EXPIRE_MINUTES
                * 60
            )
        )

        payload = {
            "amount": int(
                (
                    balance * 100
                ).quantize(
                    Decimal("1")
                )
            ),
            "currency": "INR",
            "accept_partial": False,
            "reference_id": reference_id,
            "description": (
                f"SafeColony maintenance bill #{bill.id}"
            ),
            "expire_by": expire_by,
            "reminder_enable": False,
            "notes": {
                "bill_id": str(
                    bill.id
                ),
                "organization_id": str(
                    current_user.organization_id
                ),
                "resident_id": str(
                    bill.resident_id
                ),
            },
        }

        token = base64.b64encode(
            (
                f"{settings.RAZORPAY_KEY_ID}:"
                f"{settings.RAZORPAY_KEY_SECRET}"
            ).encode()
        ).decode()

        request = urllib.request.Request(
            "https://api.razorpay.com/v1/payment_links",
            data=json.dumps(
                payload
            ).encode(),
            headers={
                "Authorization": f"Basic {token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:

            with urllib.request.urlopen(
                request,
                timeout=20,
            ) as response:

                result = json.loads(
                    response.read().decode()
                )

        except urllib.error.HTTPError as exc:

            body = exc.read().decode(
                errors="replace"
            )

            logger.error(
                "Razorpay payment link HTTP %s: %s",
                exc.code,
                body,
            )

            raise BadRequestException(
                "Unable to start online payment. Please try again."
            )

        except Exception:

            logger.exception(
                "Razorpay payment link creation failed"
            )

            raise BadRequestException(
                "Unable to start online payment. Please try again."
            )

        return {
            "bill_id": bill.id,
            "amount": balance,
            "mode": "RAZORPAY",
            "reference_id": reference_id,
            "payment_link_id": result.get("id"),
            "payment_url": (
                result.get("short_url")
                or result.get("url")
                or ""
            ),
            "expires_at": expire_by,
            "upi_id": None,
            "display_name": None,
            "payment_phone": None,
            "message": (
                "Complete the hosted payment. "
                "SafeColony marks the bill PAID only "
                "after the verified gateway webhook."
            ),
        }

    # ==========================================================
    # Direct UPI Payment Submission
    # ==========================================================

    def submit_direct_upi_payment(
        self,
        current_user: User,
        bill_id: int,
        data,
    ):
        """
        Resident can submit UPI payment ONLY for
        their own maintenance bill.
        """

        # ------------------------------------------------------
        # IMPORTANT SECURITY FIX
        # ------------------------------------------------------

        bill = self._get_current_resident_bill(
            current_user,
            bill_id,
        )

        remaining = self._payment_balance(
            bill
        )

        if remaining <= 0:
            raise BadRequestException(
                "Maintenance bill is already paid."
            )

        if data.amount > remaining:
            raise BadRequestException(
                "Payment amount cannot exceed the outstanding balance."
            )

        organization = (
            self.db.query(Organization)
            .filter(
                Organization.id
                == current_user.organization_id
            )
            .first()
        )

        if (
            not organization
            or (
                organization.payment_mode
                or ""
            ).upper()
            != "DIRECT_UPI"
        ):
            raise BadRequestException(
                "Direct UPI is not enabled for this community."
            )

        duplicate = (
            self.db.query(
                MaintenancePayment.id
            )
            .filter(
                MaintenancePayment.reference
                == data.reference,
                MaintenancePayment.bill_id
                == bill.id,
            )
            .first()
        )

        if duplicate:
            raise ConflictException(
                "This UPI transaction reference has already been submitted."
            )

        payment = MaintenancePayment(
            bill_id=bill.id,
            amount=data.amount,
            payment_method="DIRECT_UPI",
            reference=data.reference,
            status="PENDING",
            recorded_by=current_user.id,
        )

        self.db.add(payment)
        self.db.flush()

        # Notify resident
        self.db.add(
            Notification(
                user_id=bill.resident.user_id,
                title="Payment Verification Pending",
                message=(
                    f"Your UPI payment of "
                    f"₹{data.amount:.2f} for maintenance "
                    "was submitted and is waiting for "
                    "administrator verification."
                ),
                notification_type="MAINTENANCE_PAYMENT",
            )
        )

        # Notify admins in same organization
        admins = (
            self.db.query(User)
            .filter(
                User.organization_id
                == bill.resident.user.organization_id,
                User.role
                == "ORGANIZATION_ADMIN",
                User.is_active.is_(True),
            )
            .all()
        )

        for admin in admins:

            self.db.add(
                Notification(
                    user_id=admin.id,
                    title="UPI Payment Verification Required",
                    message=(
                        f"{bill.resident.full_name or 'Resident'} "
                        f"submitted a UPI payment of "
                        f"₹{data.amount:.2f} for bill "
                        f"#{bill.id}. Reference: "
                        f"{data.reference}."
                    ),
                    notification_type="MAINTENANCE_PAYMENT",
                )
            )

        self.repo.commit()

        return {
            "payment_id": payment.id,
            "bill_id": bill.id,
            "status": "PENDING",
            "reference": payment.reference,
            "message": (
                "Payment submitted for administrator verification."
            ),
        }

    # ==========================================================
    # Pending Payments
    # ==========================================================

    def get_pending_payments(
        self,
        current_user: User,
    ):
        if current_user.role not in {
            "ORGANIZATION_ADMIN",
            "PROPERTY_MANAGER",
            "BLOCK_ADMIN",
        }:
            raise ForbiddenException(
                "Only maintenance administrators can view pending payment verification."
            )

        payments = self.repo.get_pending_payments(current_user.organization_id)
        if current_user.role == "BLOCK_ADMIN":
            ids = set(ScopeService.block_ids(self.db, current_user))
            payments = [
                p for p in payments
                if p.bill.resident.unit and p.bill.resident.unit.section_id in ids
            ]
        return [
            {
                "id": payment.id,
                "bill_id": payment.bill_id,
                "resident_id": payment.bill.resident_id,
                "resident_name": (payment.bill.resident.full_name or "Resident"),
                "unit_number": payment.bill.resident.unit_number,
                "amount": payment.amount,
                "reference": payment.reference,
                "payment_method": payment.payment_method,
                "status": payment.status,
                "paid_at": payment.paid_at,
            }
            for payment in payments
        ]

    # ==========================================================
    # Verify Direct UPI Payment
    # ==========================================================

    def verify_direct_upi_payment(
        self,
        current_user: User,
        payment_id: int,
        approve: bool,
    ):
        if current_user.role not in {
            "ORGANIZATION_ADMIN",
            "PROPERTY_MANAGER",
            "BLOCK_ADMIN",
        }:
            raise ForbiddenException(
                "Only maintenance administrators can verify payments."
            )

        payment = self.repo.get_payment(
            payment_id
        )

        if not payment:
            raise NotFoundException(
                "Payment"
            )

        bill = payment.bill

        if (
            bill.resident.user.organization_id
            != current_user.organization_id
        ):
            raise ForbiddenException(
                "Payment does not belong to your organization."
            )
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if not bill.resident.unit or bill.resident.unit.section_id not in ids:
                raise ForbiddenException("Payment is outside your assigned block.")

        if payment.status != "PENDING":
            raise BadRequestException(
                "This payment has already been processed."
            )

        if not approve:

            payment.status = "REJECTED"

            self.db.add(
                Notification(
                    user_id=bill.resident.user_id,
                    title="Maintenance Payment Rejected",
                    message=(
                        f"Your UPI payment reference "
                        f"{payment.reference or '-'} "
                        "could not be verified. "
                        "Please contact the administrator."
                    ),
                    notification_type="MAINTENANCE_PAYMENT",
                )
            )

            self.repo.commit()

            return {
                "status": "REJECTED",
                "bill_id": bill.id,
                "payment_id": payment.id,
            }

        remaining = self._payment_balance(
            bill
        )

        payment_amount = min(
            Decimal(
                str(payment.amount)
            ),
            remaining,
        )

        if payment_amount <= 0:

            payment.status = "REJECTED"

            self.repo.commit()

            raise BadRequestException(
                "The bill has no remaining balance."
            )

        payment.status = "VERIFIED"

        payment.verified_at = datetime.utcnow()

        payment.verified_by = current_user.id

        bill.amount_paid = (
            Decimal(
                str(bill.amount_paid)
            )
            + payment_amount
        )

        if bill.amount_paid >= bill.total_due:

            bill.amount_paid = bill.total_due

            bill.status = "PAID"

            bill.paid_at = datetime.utcnow()

        else:

            bill.status = "PARTIAL"

        event_bus.publish(MaintenancePaidEvent(
            bill_id=bill.id,
            organization_id=current_user.organization_id,
            resident_id=bill.resident_id,
            amount=str(payment_amount),
            payment_method=payment.payment_method,
        ))

        self.db.add(
            Notification(
                user_id=bill.resident.user_id,
                title="Maintenance Payment Verified",
                message=(
                    f"Your UPI payment of "
                    f"₹{payment_amount:.2f} was verified. "
                    f"Outstanding balance: "
                    f"₹{(bill.total_due - bill.amount_paid):.2f}."
                ),
                notification_type="MAINTENANCE_PAYMENT",
            )
        )

        self.repo.commit()

        return {
            "status": "VERIFIED",
            "bill_id": bill.id,
            "payment_id": payment.id,
            "bill_status": bill.status,
        }

    # ==========================================================
    # Razorpay Webhook
    # ==========================================================

    def handle_razorpay_webhook(
        self,
        raw_body: bytes,
        signature: str | None,
    ):
        import hashlib
        import hmac
        import json

        from app.config import settings

        if not settings.RAZORPAY_WEBHOOK_SECRET:
            raise ForbiddenException(
                "Payment webhook is not configured."
            )

        if not signature:
            raise ForbiddenException(
                "Missing payment webhook signature."
            )

        expected = hmac.new(
            settings.RAZORPAY_WEBHOOK_SECRET.encode(),
            raw_body,
            hashlib.sha256,
        ).hexdigest()

        if not hmac.compare_digest(
            expected,
            signature,
        ):
            raise ForbiddenException(
                "Invalid payment webhook signature."
            )

        event = json.loads(
            raw_body.decode("utf-8")
        )

        event_name = event.get(
            "event"
        )

        if event_name != "payment_link.paid":

            return {
                "received": True,
                "processed": False,
                "event": event_name,
            }

        payment_link = (
            event.get("payload", {})
            .get("payment_link", {})
            .get("entity", {})
        )

        reference_id = payment_link.get(
            "reference_id"
        )

        if (
            not reference_id
            or not reference_id.startswith(
                "SAFE-MAINT-"
            )
        ):
            return {
                "received": True,
                "processed": False,
                "reason": "Unknown reference",
            }

        try:

            bill_id = int(
                reference_id.split("-")[2]
            )

        except (
            IndexError,
            ValueError,
        ):

            return {
                "received": True,
                "processed": False,
                "reason": "Invalid reference",
            }

        bill = self.repo.get_bill(
            bill_id
        )

        if not bill:

            return {
                "received": True,
                "processed": False,
                "reason": "Bill not found",
            }

        payment_reference = (
            payment_link.get("id")
            or reference_id
        )

        duplicate = (
            self.db.query(
                MaintenancePayment.id
            )
            .filter(
                MaintenancePayment.reference
                == payment_reference
            )
            .first()
        )

        if duplicate:

            return {
                "received": True,
                "processed": True,
                "duplicate": True,
                "bill_id": bill.id,
                "status": bill.status,
            }

        order_entity = (
            event.get("payload", {})
            .get("order", {})
            .get("entity", {})
        )

        payment_entity = (
            event.get("payload", {})
            .get("payment", {})
            .get("entity", {})
        )

        raw_amount_paid = (
            order_entity.get("amount_paid")
            or payment_entity.get("amount")
            or payment_entity.get("amount_paid")
            or 0
        )

        amount_paid = (
            Decimal(
                str(raw_amount_paid)
            )
            / Decimal("100")
        )

        if amount_paid <= 0:

            return {
                "received": True,
                "processed": False,
                "reason": "No captured amount",
            }

        remaining = self._payment_balance(
            bill
        )

        payment_amount = min(
            amount_paid,
            remaining,
        )

        if payment_amount > 0:

            payment = MaintenancePayment(
                bill_id=bill.id,
                amount=payment_amount,
                payment_method="RAZORPAY",
                reference=payment_reference,
                status="VERIFIED",
                verified_at=datetime.utcnow(),
                recorded_by=bill.resident.user_id,
            )

            self.db.add(payment)

            bill.amount_paid = (
                Decimal(
                    str(bill.amount_paid)
                )
                + payment_amount
            )

            if bill.amount_paid >= bill.total_due:

                bill.amount_paid = bill.total_due

                bill.status = "PAID"

                bill.paid_at = datetime.utcnow()

            else:

                bill.status = "PARTIAL"

            event_bus.publish(MaintenancePaidEvent(
                bill_id=bill.id,
                organization_id=bill.resident.user.organization_id,
                resident_id=bill.resident_id,
                amount=str(payment_amount),
                payment_method="RAZORPAY",
            ))

            self.db.add(
                Notification(
                    user_id=bill.resident.user_id,
                    title="Maintenance Payment Successful",
                    message=(
                        f"Your maintenance payment of "
                        f"₹{payment_amount:.2f} "
                        "was received successfully."
                    ),
                    notification_type="MAINTENANCE_PAYMENT",
                )
            )

            admins = (
                self.db.query(User)
                .filter(
                    User.organization_id
                    == bill.resident.user.organization_id,
                    User.role
                    == "ORGANIZATION_ADMIN",
                    User.is_active.is_(True),
                )
                .all()
            )

            for admin in admins:

                self.db.add(
                    Notification(
                        user_id=admin.id,
                        title="Maintenance Payment Received",
                        message=(
                            f"{bill.resident.full_name or 'Resident'} "
                            f"paid ₹{payment_amount:.2f} online. "
                            f"Bill #{bill.id} is "
                            f"{bill.status}."
                        ),
                        notification_type="MAINTENANCE_PAYMENT",
                    )
                )

            self.repo.commit()

        return {
            "received": True,
            "processed": True,
            "bill_id": bill.id,
            "status": bill.status,
        }

    # ==========================================================
    # Manual Payment / Invoice / Receipt
    # ==========================================================

    def _admin_bill(self, current_user: User, bill_id: int):
        bill = self.repo.get_bill(bill_id)
        if not bill:
            raise NotFoundException("Maintenance bill")
        if not bill.resident.user or bill.resident.user.organization_id != current_user.organization_id:
            raise ForbiddenException("Bill does not belong to your organization.")
        if not bill.resident.is_primary:
            raise ForbiddenException("Family members do not have separate maintenance bills. Manage the primary resident's unit bill instead.")
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if not bill.resident.unit or bill.resident.unit.section_id not in ids:
                raise ForbiddenException("Bill is outside your assigned block.")
        return bill

    def update_bill(self, current_user: User, bill_id: int, data):
        bill = self._admin_bill(current_user, bill_id)
        if bill.period.status == "CLOSED":
            raise BadRequestException("A bill in a closed maintenance period cannot be edited.")
        if bill.amount_paid > 0 or bill.status in {"PAID", "PARTIAL"}:
            raise BadRequestException("A bill with a recorded payment cannot be edited. Create an adjustment instead.")
        if data.due_date < bill.period.month:
            raise BadRequestException("Due date cannot be before the billing month.")
        bill.amount = data.amount
        bill.due_date = data.due_date
        bill.total_due = Decimal(str(data.amount)) + Decimal(str(bill.carried_forward)) + Decimal(str(bill.late_fee))
        bill.status = "UNPAID"
        bill.updated_at = datetime.utcnow()
        self.db.add(Notification(
            user_id=bill.resident.user_id,
            title="Maintenance Bill Updated",
            message=f"Your maintenance bill was updated to ₹{bill.total_due:.2f}. Due date: {bill.due_date.strftime('%d-%m-%Y')}.",
            notification_type="MAINTENANCE_DUE",
        ))
        self.repo.commit()
        return self._bill_response(bill)

    def delete_bill(self, current_user: User, bill_id: int):
        bill = self._admin_bill(current_user, bill_id)
        if bill.period.status == "CLOSED":
            raise BadRequestException("A bill in a closed maintenance period cannot be deleted.")
        if bill.amount_paid > 0 or bill.status in {"PAID", "PARTIAL"} or bill.payments:
            raise BadRequestException("A bill with a recorded payment cannot be deleted.")
        resident_user_id = bill.resident.user_id
        self.db.delete(bill)
        if resident_user_id:
            self.db.add(Notification(
                user_id=resident_user_id,
                title="Maintenance Bill Cancelled",
                message="Your previously generated maintenance bill has been cancelled by the administrator.",
                notification_type="MAINTENANCE_DUE",
            ))
        self.repo.commit()
        return {"success": True, "bill_id": bill_id}

    def record_payment(self, current_user: User, bill_id: int, data):
        if current_user.role not in {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "BLOCK_ADMIN"}:
            raise ForbiddenException("Only maintenance administrators can record manual maintenance payments.")
        bill = self.repo.get_bill(bill_id)
        if not bill:
            raise NotFoundException("Maintenance bill")
        if not bill.resident.user or bill.resident.user.organization_id != current_user.organization_id:
            raise ForbiddenException("Bill does not belong to your organization.")
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if not bill.resident.unit or bill.resident.unit.section_id not in ids:
                raise ForbiddenException("Bill is outside your assigned block.")

        organization = self.db.query(Organization).filter(
            Organization.id == current_user.organization_id
        ).first()
        if organization:
            self._apply_late_fee(bill, organization)

        remaining = self._payment_balance(bill)
        if data.amount > remaining:
            raise BadRequestException("Payment amount cannot exceed the outstanding balance.")

        payment = MaintenancePayment(
            bill_id=bill.id,
            amount=data.amount,
            payment_method=data.payment_method.upper(),
            reference=data.reference,
            status="VERIFIED",
            verified_at=datetime.utcnow(),
            verified_by=current_user.id,
            recorded_by=current_user.id,
        )
        self.db.add(payment)
        bill.amount_paid = Decimal(str(bill.amount_paid)) + data.amount
        if bill.amount_paid >= bill.total_due:
            bill.amount_paid = bill.total_due
            bill.status = "PAID"
            bill.paid_at = datetime.utcnow()
        else:
            bill.status = "PARTIAL"

        event_bus.publish(MaintenancePaidEvent(
            bill_id=bill.id,
            organization_id=current_user.organization_id,
            resident_id=bill.resident_id,
            amount=str(data.amount),
            payment_method=data.payment_method.upper(),
        ))
        self.db.add(Notification(
            user_id=bill.resident.user_id,
            title="Maintenance Payment Recorded",
            message=f"Payment of ₹{data.amount:.2f} was recorded. Outstanding: ₹{self._payment_balance(bill):.2f}.",
            notification_type="MAINTENANCE_PAYMENT",
        ))
        self.repo.commit()
        return self._bill_response(bill)

    def invoice(self, current_user: User, bill_id: int):
        bill = (
            self._get_current_resident_bill(current_user, bill_id)
            if current_user.role == "RESIDENT"
            else self.repo.get_bill(bill_id)
        )
        if not bill:
            raise NotFoundException("Maintenance bill")
        if bill.resident.user.organization_id != current_user.organization_id:
            raise ForbiddenException("Bill does not belong to your organization.")
        if current_user.role == "BLOCK_ADMIN":
            ids = ScopeService.block_ids(self.db, current_user)
            if not bill.resident.unit or bill.resident.unit.section_id not in ids:
                raise ForbiddenException("Bill is outside your assigned block.")
        organization = self.db.query(Organization).filter(
            Organization.id == current_user.organization_id
        ).first()
        if organization:
            self._apply_late_fee(bill, organization)
            self.repo.commit()
        return {
            "bill_id": bill.id,
            "invoice_number": f"INV-MAINT-{bill.id}",
            "resident_name": bill.resident.full_name or "Resident",
            "unit_number": bill.resident.unit_number,
            "billing_month": bill.period.month,
            "issue_date": bill.period.month,
            "due_date": bill.due_date,
            "maintenance_amount": bill.amount,
            "carried_forward": bill.carried_forward,
            "late_fee": bill.late_fee,
            "total_due": bill.total_due,
            "amount_paid": bill.amount_paid,
            "balance": self._payment_balance(bill),
        }

    def receipt(self, current_user: User, payment_id: int):
        payment = self.repo.get_payment(payment_id)
        if not payment:
            raise NotFoundException("Payment")
        bill = payment.bill
        if bill.resident.user.organization_id != current_user.organization_id:
            raise ForbiddenException("Payment does not belong to your organization.")
        if current_user.role == "RESIDENT" and bill.resident.user_id != current_user.id:
            raise ForbiddenException("You can only view your own receipt.")
        return {
            "receipt_number": f"RCT-MAINT-{payment.id}",
            "payment_id": payment.id,
            "bill_id": bill.id,
            "resident_name": bill.resident.full_name or "Resident",
            "unit_number": bill.resident.unit_number,
            "amount": payment.amount,
            "payment_method": payment.payment_method,
            "reference": payment.reference,
            "paid_at": payment.paid_at,
            "status": payment.status,
        }

    # ==========================================================
    # Daily Due Reminders
    # ==========================================================

    def send_daily_due_reminders(
        self,
    ):
        today = date.today()

        bills = self.repo.get_unpaid_due_bills(
            today
        )

        sent = 0

        for bill in bills:

            user = bill.resident.user

            if (
                not user
                or self.repo.notification_sent_today(
                    user.id,
                    bill.id,
                    today,
                )
            ):
                continue

            balance = (
                Decimal(
                    str(bill.total_due)
                )
                - Decimal(
                    str(bill.amount_paid)
                )
            )

            self.db.add(
                Notification(
                    user_id=user.id,
                    title="Maintenance Payment Due",
                    message=(
                        f"Maintenance bill #{bill.id} "
                        f"is still unpaid. "
                        f"Outstanding amount: "
                        f"₹{balance:.2f}. "
                        "Please complete payment."
                    ),
                    notification_type="MAINTENANCE_DUE",
                )
            )

            sent += 1

        self.repo.commit()

        logger.info(
            "Maintenance reminders sent=%s",
            sent,
        )

        return sent