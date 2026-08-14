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

    # --------------------------------------------------
    # Maintenance Periods
    # --------------------------------------------------

    def get_period(
        self,
        period_id: int,
        organization_id: int,
        section_id: int | None = None,
        include_community: bool = True,
    ):
        q = (
            self.db.query(MaintenancePeriod)
            .filter(
                MaintenancePeriod.id == period_id,
                MaintenancePeriod.organization_id == organization_id,
            )
        )
        if section_id is not None:
            q = q.filter(MaintenancePeriod.section_id == section_id)
        elif not include_community:
            q = q.filter(MaintenancePeriod.section_id.is_(None))
        return q.first()

    def get_period_by_month(
        self,
        organization_id: int,
        month: date,
        section_id: int | None = None,
    ):
        q = (
            self.db.query(MaintenancePeriod)
            .filter(
                MaintenancePeriod.organization_id == organization_id,
                MaintenancePeriod.month == month,
            )
        )
        if section_id is None:
            q = q.filter(MaintenancePeriod.section_id.is_(None))
        else:
            q = q.filter(MaintenancePeriod.section_id == section_id)
        return q.first()

    def get_latest_period(
        self,
        organization_id: int,
        section_id: int | None = None,
    ):
        q = (
            self.db.query(MaintenancePeriod)
            .filter(MaintenancePeriod.organization_id == organization_id)
        )
        if section_id is None:
            q = q.filter(MaintenancePeriod.section_id.is_(None))
        else:
            q = q.filter(MaintenancePeriod.section_id == section_id)
        return q.order_by(MaintenancePeriod.month.desc()).first()

    def create_period(
        self,
        period: MaintenancePeriod,
    ):
        self.db.add(period)
        self.db.flush()
        return period

    # --------------------------------------------------
    # Resident Outstanding Balance
    # --------------------------------------------------

    def outstanding_balance_before(
        self,
        organization_id: int,
        resident_id: int,
        month: date,
    ):
        """
        Return unpaid/partial maintenance amount carried
        forward from earlier periods for THIS resident only.
        """

        amount = (
            self.db.query(
                func.coalesce(
                    func.sum(
                        MaintenanceBill.total_due
                        - MaintenanceBill.amount_paid
                    ),
                    0,
                )
            )
            .join(
                MaintenanceBill.period
            )
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

    # --------------------------------------------------
    # Bills
    # --------------------------------------------------

    def create_bill(
        self,
        bill: MaintenanceBill,
    ):
        self.db.add(bill)
        return bill

    def get_bill(
        self,
        bill_id: int,
    ):
        """
        Load a maintenance bill with the resident,
        user and unit information.
        """

        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.user
                ),
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.unit
                ),
            )
            .filter(
                MaintenanceBill.id == bill_id,
            )
            .first()
        )

    def get_bill_for_resident(
        self,
        bill_id: int,
        resident_id: int,
    ):
        """
        IMPORTANT SECURITY METHOD.

        Return a bill only when it belongs to the
        requested resident.

        This prevents a resident from accessing another
        resident's maintenance bill by changing bill_id.
        """

        return (
            self.db.query(MaintenanceBill)
            .join(
                MaintenanceBill.resident
            )
            .options(
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.user
                ),
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.unit
                ),
                joinedload(
                    MaintenanceBill.period
                ),
            )
            .filter(
                MaintenanceBill.id == bill_id,
                MaintenanceBill.resident_id == resident_id,
            )
            .first()
        )

    def get_bills_for_period(
        self,
        period_id: int,
    ):
        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.user
                ),
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.unit
                ),
            )
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period_id,
                Resident.is_primary.is_(True),
            )
            .order_by(
                MaintenanceBill.status.asc(),
                MaintenanceBill.id.asc(),
            )
            .all()
        )


    def get_bills_for_section(
        self,
        period_id: int,
        section_id: int,
    ):
        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(MaintenanceBill.resident).joinedload(Resident.user),
                joinedload(MaintenanceBill.resident).joinedload(Resident.unit),
            )
            .join(MaintenanceBill.resident)
            .join(Resident.unit)
            .filter(
                MaintenanceBill.period_id == period_id,
                Resident.is_primary.is_(True),
                __import__("app.models.unit", fromlist=["Unit"]).Unit.section_id == section_id,
            )
            .order_by(MaintenanceBill.status.asc(), MaintenanceBill.id.asc())
            .all()
        )

    def get_bills_for_resident(
        self,
        resident_id: int,
    ):
        """
        Return maintenance history for ONLY this resident.
        """

        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(
                    MaintenanceBill.period
                ),
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.user
                ),
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.unit
                ),
            )
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.resident_id == resident_id,
                Resident.is_primary.is_(True),
            )
            .order_by(
                MaintenanceBill.due_date.desc(),
            )
            .all()
        )

    # --------------------------------------------------
    # Expenses
    # --------------------------------------------------

    def create_expense(
        self,
        expense: MaintenanceExpense,
    ):
        self.db.add(expense)
        self.db.flush()
        return expense

    def get_expenses_for_period(
        self,
        period_id: int,
    ):
        return (
            self.db.query(MaintenanceExpense)
            .filter(
                MaintenanceExpense.period_id == period_id,
            )
            .order_by(
                MaintenanceExpense.spent_on.desc(),
                MaintenanceExpense.id.desc(),
            )
            .all()
        )

    # --------------------------------------------------
    # Unpaid Bills / Notifications
    # --------------------------------------------------

    def get_unpaid_due_bills(
        self,
        today: date,
    ):
        return (
            self.db.query(MaintenanceBill)
            .options(
                joinedload(
                    MaintenanceBill.resident
                ).joinedload(
                    Resident.user
                )
            )
            .filter(
                MaintenanceBill.due_date <= today,
                Resident.is_primary.is_(True),
                MaintenanceBill.status.in_(
                    [
                        "UNPAID",
                        "PARTIAL",
                    ]
                ),
            )
            .all()
        )

    def notification_sent_today(
        self,
        user_id: int,
        bill_id: int,
        today: date,
    ):
        from app.models.notification import Notification

        prefix = (
            f"Maintenance bill #{bill_id} is still unpaid."
        )

        return (
            self.db.query(
                Notification.id
            )
            .filter(
                Notification.user_id == user_id,
                Notification.notification_type
                == "MAINTENANCE_DUE",
                Notification.title
                == "Maintenance Payment Due",
                Notification.message.like(
                    f"{prefix}%"
                ),
                Notification.created_at
                >= datetime.combine(
                    today,
                    datetime.min.time(),
                ),
            )
            .first()
            is not None
        )

    # --------------------------------------------------
    # Aggregation
    # --------------------------------------------------

    def sum_bills(
        self,
        period_id: int,
        field,
    ):
        return (
            self.db.query(
                func.coalesce(
                    func.sum(field),
                    0,
                )
            )
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period_id,
                Resident.is_primary.is_(True),
            )
            .scalar()
            or 0
        )

    def count_bills(
        self,
        period_id: int,
        status: str | None = None,
    ):
        query = (
            self.db.query(
                func.count(
                    MaintenanceBill.id
                )
            )
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period_id,
                Resident.is_primary.is_(True),
            )
        )

        if status:
            query = query.filter(
                MaintenanceBill.status
                == status
            )

        return query.scalar() or 0

    def sum_expenses(
        self,
        period_id: int,
    ):
        return (
            self.db.query(
                func.coalesce(
                    func.sum(
                        MaintenanceExpense.amount
                    ),
                    0,
                )
            )
            .filter(
                MaintenanceExpense.period_id
                == period_id
            )
            .scalar()
            or 0
        )

    # --------------------------------------------------
    # Transaction
    # --------------------------------------------------

    def commit(self):
        self.db.commit()

    def rollback(self):
        self.db.rollback()

    # --------------------------------------------------
    # Pending Payments
    # --------------------------------------------------

    def get_pending_payments(
        self,
        organization_id: int,
    ):
        return (
            self.db.query(
                MaintenancePayment
            )
            .join(
                MaintenanceBill,
                MaintenancePayment.bill_id
                == MaintenanceBill.id,
            )
            .join(
                Resident,
                MaintenanceBill.resident_id
                == Resident.id,
            )
            .join(
                User,
                Resident.user_id
                == User.id,
            )
            .options(
                joinedload(
                    MaintenancePayment.bill
                )
                .joinedload(
                    MaintenanceBill.resident
                )
                .joinedload(
                    Resident.user
                ),
                joinedload(
                    MaintenancePayment.bill
                )
                .joinedload(
                    MaintenanceBill.resident
                )
                .joinedload(
                    Resident.unit
                ),
            )
            .filter(
                User.organization_id == organization_id,
                Resident.is_primary.is_(True),
                MaintenancePayment.status == "PENDING",
            )
            .order_by(
                MaintenancePayment.id.desc(),
            )
            .all()
        )

    # --------------------------------------------------
    # Individual Payment
    # --------------------------------------------------

    def get_payment(
        self,
        payment_id: int,
    ):
        return (
            self.db.query(
                MaintenancePayment
            )
            .options(
                joinedload(
                    MaintenancePayment.bill
                )
                .joinedload(
                    MaintenanceBill.resident
                )
                .joinedload(
                    Resident.user
                ),
                joinedload(
                    MaintenancePayment.bill
                )
                .joinedload(
                    MaintenanceBill.resident
                )
                .joinedload(
                    Resident.unit
                ),
            )
            .filter(
                MaintenancePayment.id
                == payment_id,
            )
            .first()
        )