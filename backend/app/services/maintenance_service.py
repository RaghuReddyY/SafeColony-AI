from datetime import date, datetime
from decimal import Decimal

from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_expense import MaintenanceExpense
from app.models.maintenance_payment import MaintenancePayment
from app.models.maintenance_period import MaintenancePeriod
from app.models.notification import Notification
from app.repositories.maintenance_repository import MaintenanceRepository
from app.repositories.resident_repository import ResidentRepository
from app.models.user import User


class MaintenanceService:
    def __init__(self, repo: MaintenanceRepository):
        self.repo = repo
        self.db = repo.db
        self.resident_repo = ResidentRepository(self.db)

    def _active_residents(self, organization_id: int):
        return self.resident_repo.get_dropdown_by_organization(organization_id)

    def _previous_closing_balance(self, organization_id: int):
        previous = self.repo.get_latest_period(organization_id)
        if not previous:
            return Decimal("0.00")
        return Decimal(str(previous.opening_balance)) + self.repo.sum_bills(previous.id, MaintenanceBill.amount_paid) - self.repo.sum_expenses(previous.id)

    def create_period(self, current_user: User, data):
        existing = self.repo.get_period_by_month(current_user.organization_id, data.month.replace(day=1))
        if existing:
            raise ConflictException("Maintenance period already exists for this month.")
        if data.due_date < data.month:
            raise BadRequestException("Due date cannot be before the maintenance month.")

        opening = self._previous_closing_balance(current_user.organization_id)
        period = MaintenancePeriod(
            organization_id=current_user.organization_id,
            month=data.month.replace(day=1),
            monthly_amount=data.monthly_amount,
            due_date=data.due_date,
            opening_balance=opening,
            notes=data.notes,
            created_by=current_user.id,
        )
        self.repo.create_period(period)
        self.repo.commit()
        return period

    def generate_bills(self, current_user: User, period_id: int):
        period = self.repo.get_period(period_id, current_user.organization_id)
        if not period:
            raise NotFoundException("Maintenance period")

        residents = self._active_residents(current_user.organization_id)
        existing = {b.resident_id for b in self.repo.get_bills_for_period(period.id)}
        created = 0
        for resident in residents:
            if resident.id in existing:
                continue
            bill = MaintenanceBill(
                period_id=period.id,
                resident_id=resident.id,
                amount=period.monthly_amount,
                carried_forward=Decimal("0.00"),
                late_fee=Decimal("0.00"),
                total_due=period.monthly_amount,
                amount_paid=Decimal("0.00"),
                due_date=period.due_date,
                status="UNPAID",
            )
            self.repo.create_bill(bill)
            self.db.flush()
            if resident.user_id:
                self.db.add(Notification(
                    user_id=resident.user_id,
                    title="Maintenance Payment Due",
                    message=(
                        f"Your maintenance bill for {period.month.strftime('%B %Y')} is "
                        f"₹{period.monthly_amount:.2f}. Due date: {period.due_date.strftime('%d-%m-%Y')}."
                    ),
                    notification_type="MAINTENANCE_DUE",
                ))
            created += 1
        self.repo.commit()
        return {"created": created, "skipped": len(existing)}

    def add_expense(self, current_user: User, period_id: int, data):
        period = self.repo.get_period(period_id, current_user.organization_id)
        if not period:
            raise NotFoundException("Maintenance period")
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

    def _bill_response(self, bill: MaintenanceBill):
        resident = bill.resident
        return {
            "id": bill.id,
            "period_id": bill.period_id,
            "resident_id": bill.resident_id,
            "resident_name": resident.full_name or "Resident",
            "property_name": resident.property_name,
            "section_name": resident.section_name,
            "unit_number": resident.unit_number,
            "amount": bill.amount,
            "carried_forward": bill.carried_forward,
            "late_fee": bill.late_fee,
            "total_due": bill.total_due,
            "amount_paid": bill.amount_paid,
            "balance": max(Decimal("0.00"), Decimal(str(bill.total_due)) - Decimal(str(bill.amount_paid))),
            "due_date": bill.due_date,
            "status": bill.status,
            "paid_at": bill.paid_at,
        }

    def _period_response(self, period: MaintenancePeriod):
        billed = self.repo.sum_bills(period.id, MaintenanceBill.total_due)
        collected = self.repo.sum_bills(period.id, MaintenanceBill.amount_paid)
        expenses = self.repo.sum_expenses(period.id)
        closing = Decimal(str(period.opening_balance)) + Decimal(str(collected)) - Decimal(str(expenses))
        return {
            "id": period.id,
            "organization_id": period.organization_id,
            "month": period.month,
            "monthly_amount": period.monthly_amount,
            "due_date": period.due_date,
            "opening_balance": period.opening_balance,
            "billed_total": billed,
            "collected_total": collected,
            "expense_total": expenses,
            "closing_balance": closing,
            "total_bills": self.repo.count_bills(period.id),
            "paid_bills": self.repo.count_bills(period.id, "PAID"),
            "unpaid_bills": self.repo.count_bills(period.id, "UNPAID") + self.repo.count_bills(period.id, "PARTIAL"),
            "notes": period.notes,
        }

    def dashboard(self, current_user: User):
        period = self.repo.get_latest_period(current_user.organization_id)
        if not period:
            return {"period": None, "bills": [], "expenses": []}
        return {
            "period": self._period_response(period),
            "bills": [self._bill_response(b) for b in self.repo.get_bills_for_period(period.id)],
            "expenses": self.repo.get_expenses_for_period(period.id),
        }

    def resident_summary(self, current_user: User):
        resident = self.resident_repo.get_by_user_id(current_user.id)
        if not resident:
            raise NotFoundException("Resident")
        bills = self.repo.get_bills_for_resident(resident.id)
        return {
            "bill": self._bill_response(bills[0]) if bills else None,
            "history": [self._bill_response(b) for b in bills],
        }

    def record_payment(self, current_user: User, bill_id: int, data):
        bill = self.repo.get_bill(bill_id)
        if not bill:
            raise NotFoundException("Maintenance bill")

        is_admin = current_user.organization_id == bill.resident.user.organization_id and current_user.role != "RESIDENT"
        is_owner = bill.resident.user_id == current_user.id
        if not is_admin and not is_owner:
            raise ForbiddenException("You cannot update this maintenance bill.")

        remaining = Decimal(str(bill.total_due)) - Decimal(str(bill.amount_paid))
        if data.amount > remaining:
            raise BadRequestException("Payment amount cannot exceed the outstanding balance.")

        payment = MaintenancePayment(
            bill_id=bill.id,
            amount=data.amount,
            payment_method=data.payment_method,
            reference=data.reference,
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
        self.db.flush()
        if bill.resident.user_id:
            self.db.add(Notification(
                user_id=bill.resident.user_id,
                title="Maintenance Payment Recorded",
                message=f"₹{data.amount:.2f} payment recorded. Outstanding balance: ₹{(bill.total_due - bill.amount_paid):.2f}.",
                notification_type="MAINTENANCE_PAYMENT",
            ))

        # Keep organization administrators informed about collections.
        admins = (
            self.db.query(User)
            .filter(
                User.organization_id == bill.resident.user.organization_id,
                User.role == "ORGANIZATION_ADMIN",
                User.is_active.is_(True),
            )
            .all()
        )
        for admin in admins:
            self.db.add(Notification(
                user_id=admin.id,
                title="Maintenance Payment Received",
                message=(
                    f"{bill.resident.full_name or 'Resident'} paid ₹{data.amount:.2f}. "
                    f"Outstanding balance: ₹{(bill.total_due - bill.amount_paid):.2f}."
                ),
                notification_type="MAINTENANCE_PAYMENT",
            ))

        self.repo.commit()
        return self._bill_response(bill)

    def send_daily_due_reminders(self):
        today = date.today()
        bills = self.repo.get_unpaid_due_bills(today)
        sent = 0
        for bill in bills:
            user = bill.resident.user
            if not user or self.repo.notification_sent_today(user.id, bill.id, today):
                continue
            balance = Decimal(str(bill.total_due)) - Decimal(str(bill.amount_paid))
            self.db.add(Notification(
                user_id=user.id,
                title="Maintenance Payment Due",
                message=(
                    f"Maintenance bill #{bill.id} is still unpaid. Outstanding amount: ₹{balance:.2f}. "
                    "Please complete payment."
                ),
                notification_type="MAINTENANCE_DUE",
            ))
            sent += 1
        self.repo.commit()
        logger.info("Maintenance reminders sent=%s", sent)
        return sent
