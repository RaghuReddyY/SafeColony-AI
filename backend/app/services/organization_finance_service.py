from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import joinedload

from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_expense import MaintenanceExpense
from app.models.maintenance_period import MaintenancePeriod
from app.models.organization import Organization
from app.models.resident import Resident
from app.models.unit import Unit
from app.models.user import User
from app.repositories.community_finance_repository import CommunityFinanceRepository
from app.repositories.maintenance_repository import MaintenanceRepository
from app.services.community_finance_service import CommunityFinanceService


class OrganizationFinanceService:
    """Read-only organization-wide finance summary for organization admins.

    This endpoint deliberately aggregates only the authenticated user's
    organization. It does not grant block admins or finance admins access to
    unrelated organization administration data.
    """

    def __init__(self, db):
        self.db = db
        self.maintenance_repo = MaintenanceRepository(db)
        self.community_repo = CommunityFinanceRepository(db)
        self.community_service = CommunityFinanceService(self.community_repo)

    def _require_organization_admin(self, user: User) -> None:
        if user.role not in {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN"}:
            raise HTTPException(
                status_code=403,
                detail="Organization-wide finance is available only to organization administrators.",
            )
        if not user.organization_id:
            raise HTTPException(
                status_code=400,
                detail="Your account is not linked to an organization.",
            )

    def _maintenance_period_summary(self, period: MaintenancePeriod):
        billed = (
            self.db.query(func.coalesce(func.sum(MaintenanceBill.amount), 0))
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period.id,
                Resident.is_primary.is_(True),
            )
            .scalar()
            or Decimal("0")
        )
        collected = (
            self.db.query(func.coalesce(func.sum(MaintenanceBill.amount_paid), 0))
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period.id,
                Resident.is_primary.is_(True),
            )
            .scalar()
            or Decimal("0")
        )
        outstanding = (
            self.db.query(
                func.coalesce(
                    func.sum(MaintenanceBill.total_due - MaintenanceBill.amount_paid),
                    0,
                )
            )
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period.id,
                Resident.is_primary.is_(True),
                MaintenanceBill.total_due > MaintenanceBill.amount_paid,
            )
            .scalar()
            or Decimal("0")
        )
        expenses = (
            self.db.query(func.coalesce(func.sum(MaintenanceExpense.amount), 0))
            .filter(MaintenanceExpense.period_id == period.id)
            .scalar()
            or Decimal("0")
        )
        total_bills = (
            self.db.query(func.count(MaintenanceBill.id))
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period.id,
                Resident.is_primary.is_(True),
            )
            .scalar()
            or 0
        )
        paid_bills = (
            self.db.query(func.count(MaintenanceBill.id))
            .join(MaintenanceBill.resident)
            .filter(
                MaintenanceBill.period_id == period.id,
                Resident.is_primary.is_(True),
                MaintenanceBill.status == "PAID",
            )
            .scalar()
            or 0
        )

        return {
            "section_id": period.section_id,
            "section_name": (
                period.section.name
                if period.section is not None
                else "Organization-wide"
            ),
            "month": period.month,
            "status": period.status,
            "opening_balance": period.opening_balance,
            "billed_total": billed,
            "collected_total": collected,
            "expense_total": expenses,
            "outstanding_total": outstanding,
            "balance": Decimal(str(period.opening_balance)) + Decimal(str(collected)) - Decimal(str(expenses)),
            "total_bills": int(total_bills),
            "paid_bills": int(paid_bills),
            "pending_bills": int(total_bills - paid_bills),
        }

    def _latest_maintenance_periods(self, organization_id: int):
        # Include one latest period for every block/section plus any
        # organization-wide period. This keeps the dashboard useful without
        # downloading every historical bill into the home screen.
        periods = (
            self.db.query(MaintenancePeriod)
            .options(joinedload(MaintenancePeriod.section))
            .filter(MaintenancePeriod.organization_id == organization_id)
            .order_by(MaintenancePeriod.month.desc(), MaintenancePeriod.id.desc())
            .all()
        )

        latest = {}
        for period in periods:
            key = period.section_id
            if key not in latest:
                latest[key] = period
        return list(latest.values())

    def _community_fund_summary(self, fund, households):
        response = self.community_service._response(
            fund,
            viewer=None,
            households=households,
        )
        statuses = response["household_status"]
        if fund.contribution_mode == "FIXED":
            paid = sum(1 for row in statuses if row["status"] == "PAID")
            pending = sum(
                1
                for row in statuses
                if row["status"] in {"UNPAID", "PARTIAL"}
            )
        else:
            paid = sum(1 for row in statuses if row["status"] == "PAID")
            pending = sum(1 for row in statuses if row["status"] == "NOT_CONTRIBUTED")

        return {
            "id": fund.id,
            "title": fund.title,
            "status": fund.status,
            "contribution_mode": fund.contribution_mode,
            "per_unit_amount": fund.per_unit_amount,
            "target_amount": fund.target_amount,
            "collected_amount": response["collected_amount"],
            "expense_amount": response["expense_amount"],
            "balance": response["balance"],
            "contributor_count": response["contributor_count"],
            "paid_households": paid,
            "pending_households": pending,
        }

    def summary(self, user: User):
        self._require_organization_admin(user)

        organization = (
            self.db.query(Organization)
            .filter(Organization.id == user.organization_id)
            .first()
        )
        if not organization:
            raise HTTPException(status_code=404, detail="Organization not found.")

        maintenance_sections = [
            self._maintenance_period_summary(period)
            for period in self._latest_maintenance_periods(user.organization_id)
        ]

        maintenance_billed = sum(
            (Decimal(str(row["billed_total"])) for row in maintenance_sections),
            Decimal("0"),
        )
        maintenance_collected = sum(
            (Decimal(str(row["collected_total"])) for row in maintenance_sections),
            Decimal("0"),
        )
        maintenance_expenses = sum(
            (Decimal(str(row["expense_total"])) for row in maintenance_sections),
            Decimal("0"),
        )
        maintenance_outstanding = sum(
            (Decimal(str(row["outstanding_total"])) for row in maintenance_sections),
            Decimal("0"),
        )
        maintenance_balance = sum(
            (Decimal(str(row["balance"])) for row in maintenance_sections),
            Decimal("0"),
        )

        households = (
            self.db.query(Resident)
            .join(User, Resident.user_id == User.id)
            .options(
                joinedload(Resident.user),
                joinedload(Resident.unit).joinedload(Unit.section),
            )
            .filter(
                User.organization_id == user.organization_id,
                Resident.is_primary.is_(True),
                Resident.is_active.is_(True),
                User.is_active.is_(True),
            )
            .order_by(Resident.id.asc())
            .all()
        )

        funds = self.community_repo.funds(user.organization_id)
        community_funds = [
            self._community_fund_summary(fund, households)
            for fund in funds
        ]

        community_target = sum(
            (Decimal(str(row["target_amount"])) for row in community_funds if row["target_amount"] is not None),
            Decimal("0"),
        )
        community_collected = sum(
            (Decimal(str(row["collected_amount"])) for row in community_funds),
            Decimal("0"),
        )
        community_expenses = sum(
            (Decimal(str(row["expense_amount"])) for row in community_funds),
            Decimal("0"),
        )

        return {
            "organization_name": organization.name,
            "organization_code": organization.organization_code,
            "maintenance_billed_total": maintenance_billed,
            "maintenance_collected_total": maintenance_collected,
            "maintenance_expense_total": maintenance_expenses,
            "maintenance_outstanding_total": maintenance_outstanding,
            "maintenance_balance": maintenance_balance,
            "community_target_total": community_target,
            "community_collected_total": community_collected,
            "community_expense_total": community_expenses,
            "community_balance": community_collected - community_expenses,
            "community_fund_count": len(community_funds),
            "maintenance_sections": maintenance_sections,
            "community_funds": community_funds,
        }


    def money_details(self, user: User):
        self._require_organization_admin(user)
        org_id = user.organization_id
        from app.models.maintenance_bill import MaintenanceBill
        from app.models.maintenance_payment import MaintenancePayment
        from app.models.community_fund import CommunityFundContribution, CommunityFundExpense, CommunityFund
        from app.models.resident import Resident
        from app.models.unit import Unit
        from app.models.section import Section
        from app.models.property import Property

        transactions = []

        payments = (
            self.db.query(MaintenancePayment)
            .join(MaintenanceBill, MaintenancePayment.bill_id == MaintenanceBill.id)
            .join(Resident, MaintenanceBill.resident_id == Resident.id)
            .join(User, Resident.user_id == User.id)
            .outerjoin(Unit, Resident.unit_id == Unit.id)
            .outerjoin(Section, Unit.section_id == Section.id)
            .outerjoin(Property, Unit.property_id == Property.id)
            .filter(User.organization_id == org_id)
            .order_by(MaintenancePayment.paid_at.desc())
            .limit(200)
            .all()
        )
        for p in payments:
            r = p.bill.resident
            transactions.append({
                "id": f"MAINT-PAY-{p.id}",
                "kind": "MAINTENANCE_PAYMENT",
                "title": "Maintenance payment",
                "payer_or_category": r.full_name or "Resident",
                "block_name": r.section_name,
                "unit_number": r.unit_number,
                "amount": p.amount,
                "status": p.status,
                "payment_method": p.payment_method,
                "reference": p.reference,
                "occurred_at": p.paid_at.isoformat(),
            })

        bills = (
            self.db.query(MaintenanceBill)
            .join(Resident, MaintenanceBill.resident_id == Resident.id)
            .join(User, Resident.user_id == User.id)
            .filter(
                User.organization_id == org_id,
                MaintenanceBill.status.in_(["UNPAID", "PARTIAL"]),
            )
            .order_by(MaintenanceBill.due_date.asc())
            .limit(200)
            .all()
        )
        for bill in bills:
            r = bill.resident
            transactions.append({
                "id": f"MAINT-DUE-{bill.id}",
                "kind": "MAINTENANCE_DUE",
                "title": "Maintenance due",
                "payer_or_category": r.full_name or "Resident",
                "block_name": r.section_name,
                "unit_number": r.unit_number,
                "amount": bill.total_due - bill.amount_paid,
                "status": bill.status,
                "payment_method": None,
                "reference": None,
                "occurred_at": bill.due_date.isoformat(),
            })

        funds = (
            self.db.query(CommunityFundContribution)
            .join(CommunityFund, CommunityFundContribution.fund_id == CommunityFund.id)
            .filter(CommunityFund.organization_id == org_id)
            .order_by(CommunityFundContribution.collected_at.desc())
            .limit(200)
            .all()
        )
        for c in funds:
            transactions.append({
                "id": f"FUND-PAY-{c.id}",
                "kind": "COMMUNITY_CONTRIBUTION",
                "title": c.fund.title,
                "payer_or_category": c.payer_name,
                "block_name": c.block_name,
                "unit_number": c.unit_number,
                "amount": c.amount,
                "status": c.status,
                "payment_method": c.payment_method,
                "reference": c.reference,
                "occurred_at": c.collected_at.isoformat(),
            })

        expenses = (
            self.db.query(CommunityFundExpense)
            .join(CommunityFund, CommunityFundExpense.fund_id == CommunityFund.id)
            .filter(CommunityFund.organization_id == org_id)
            .order_by(CommunityFundExpense.spent_on.desc())
            .limit(200)
            .all()
        )
        for e in expenses:
            transactions.append({
                "id": f"FUND-EXP-{e.id}",
                "kind": "COMMUNITY_EXPENSE",
                "title": e.fund.title,
                "payer_or_category": e.category,
                "block_name": None,
                "unit_number": None,
                "amount": e.amount,
                "status": "EXPENSE",
                "payment_method": None,
                "reference": e.description,
                "occurred_at": e.spent_on.isoformat(),
            })

        transactions.sort(key=lambda x: x["occurred_at"], reverse=True)
        return transactions[:400]
