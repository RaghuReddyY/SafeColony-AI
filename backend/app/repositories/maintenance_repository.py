from datetime import date, datetime
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_expense import MaintenanceExpense
from app.models.maintenance_period import MaintenancePeriod
from app.models.maintenance_payment import MaintenancePayment
from app.models.resident import Resident
from app.models.user import User


class MaintenanceRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_period(self, period_id: int, organization_id: int):
        return (
            self.db.query(MaintenancePeriod)
            .filter(MaintenancePeriod.id == period_id, MaintenancePeriod.organization_id == organization_id)
            .first()
        )

    def get_period_by_month(self, organization_id: int, month: date):
        return (
            self.db.query(MaintenancePeriod)
            .filter(MaintenancePeriod.organization_id == organization_id, MaintenancePeriod.month == month)
            .first()
        )

    def get_latest_period(self, organization_id: int):
        return (
            self.db.query(MaintenancePeriod)
            .filter(MaintenancePeriod.organization_id == organization_id)
            .order_by(MaintenancePeriod.month.desc())
            .first()
        )

    def create_period(self, period: MaintenancePeriod):
        self.db.add(period)
        self.db.flush()
        return period

    def outstanding_balance_before(self, organization_id: int, resident_id: int, month: date):
        """Return all unpaid/partial maintenance carried from earlier periods."""
        amount = (
            self.db.query(
                func.coalesce(
                    func.sum(MaintenanceBill.total_due - MaintenanceBill.amount_paid),
                    0,
                )
            )
            .join(MaintenanceBill.period)
            .filter(
                MaintenanceBill.resident_id == resident_id,
                MaintenancePeriod.organization_id == organization_id,
                MaintenancePeriod.month < month,
                MaintenanceBill.total_due > MaintenanceBill.amount_paid,
            )
            .scalar()
            or 0
        )
        return amount

    def create_bill(self, bill: MaintenanceBill):
        self.db.add(bill)
        return bill

    def get_bill(self, bill_id: int):
        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(MaintenanceBill.resident).joinedload(Resident.user),
                joinedload(MaintenanceBill.resident).joinedload(Resident.unit),
            )
            .filter(MaintenanceBill.id == bill_id)
            .first()
        )

    def get_bills_for_period(self, period_id: int):
        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(MaintenanceBill.resident).joinedload(Resident.user),
                joinedload(MaintenanceBill.resident).joinedload(Resident.unit),
            )
            .filter(MaintenanceBill.period_id == period_id)
            .order_by(MaintenanceBill.status.asc(), MaintenanceBill.id.asc())
            .all()
        )

    def get_bills_for_resident(self, resident_id: int):
        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(MaintenanceBill.period),
                joinedload(MaintenanceBill.resident).joinedload(Resident.user),
                joinedload(MaintenanceBill.resident).joinedload(Resident.unit),
            )
            .filter(MaintenanceBill.resident_id == resident_id)
            .order_by(MaintenanceBill.due_date.desc())
            .all()
        )

    def create_expense(self, expense: MaintenanceExpense):
        self.db.add(expense)
        self.db.flush()
        return expense

    def get_expenses_for_period(self, period_id: int):
        return (
            self.db.query(MaintenanceExpense)
            .filter(MaintenanceExpense.period_id == period_id)
            .order_by(MaintenanceExpense.spent_on.desc(), MaintenanceExpense.id.desc())
            .all()
        )

    def get_unpaid_due_bills(self, today: date):
        return (
            self.db.query(MaintenanceBill)
            .options(joinedload(MaintenanceBill.resident).joinedload(Resident.user))
            .filter(MaintenanceBill.due_date <= today, MaintenanceBill.status.in_(["UNPAID", "PARTIAL"]))
            .all()
        )

    def notification_sent_today(self, user_id: int, bill_id: int, today: date):
        from app.models.notification import Notification
        prefix = f"Maintenance bill #{bill_id} is still unpaid."
        return (
            self.db.query(Notification.id)
            .filter(
                Notification.user_id == user_id,
                Notification.notification_type == "MAINTENANCE_DUE",
                Notification.title == "Maintenance Payment Due",
                Notification.message.like(f"{prefix}%"),
                Notification.created_at >= datetime.combine(today, datetime.min.time()),
            )
            .first()
            is not None
        )

    def sum_bills(self, period_id: int, field):
        return self.db.query(func.coalesce(func.sum(field), 0)).filter(MaintenanceBill.period_id == period_id).scalar() or 0

    def count_bills(self, period_id: int, status: str | None = None):
        q = self.db.query(func.count(MaintenanceBill.id)).filter(MaintenanceBill.period_id == period_id)
        if status:
            q = q.filter(MaintenanceBill.status == status)
        return q.scalar() or 0

    def sum_expenses(self, period_id: int):
        return self.db.query(func.coalesce(func.sum(MaintenanceExpense.amount), 0)).filter(MaintenanceExpense.period_id == period_id).scalar() or 0

    def commit(self):
        self.db.commit()

    def rollback(self):
        self.db.rollback()


    def get_pending_payments(self, organization_id: int):
        return (
            self.db.query(MaintenancePayment)
            .join(MaintenanceBill, MaintenancePayment.bill_id == MaintenanceBill.id)
            .join(Resident, MaintenanceBill.resident_id == Resident.id)
            .join(User, Resident.user_id == User.id)
            .options(
                joinedload(MaintenancePayment.bill)
                .joinedload(MaintenanceBill.resident)
                .joinedload(Resident.user)
                ,
            )
            .filter(
                User.organization_id == organization_id,
                MaintenancePayment.status == "PENDING",
            )
            .order_by(MaintenancePayment.paid_at.desc(), MaintenancePayment.id.desc())
            .all()
        )

    def get_payment(self, payment_id: int):
        return (
            self.db.query(MaintenancePayment)
            .options(
                joinedload(MaintenancePayment.bill)
                .joinedload(MaintenanceBill.resident)
                .joinedload(Resident.user)
            )
            .filter(MaintenancePayment.id == payment_id)
            .first()
        )
