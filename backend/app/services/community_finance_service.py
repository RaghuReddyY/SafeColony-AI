import time
from decimal import Decimal
from urllib.parse import quote

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.models.community_fund import CommunityFund, CommunityFundContribution, CommunityFundExpense
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.user import User
from app.repositories.community_finance_repository import CommunityFinanceRepository
from sqlalchemy.orm import joinedload


class CommunityFinanceService:
    def __init__(self, repo: CommunityFinanceRepository):
        self.repo = repo
        self.db = repo.db

    def _check_manager(self, user):
        if user.role not in {"ORGANIZATION_ADMIN", "COMMUNITY_FINANCE_ADMIN"}:
            raise ForbiddenException("You do not have permission to manage community-wide funds.")

    def _primary_resident(self, user):
        resident = (
            self.db.query(Resident)
            .filter(Resident.user_id == user.id, Resident.is_active.is_(True))
            .first()
        )
        if not resident:
            raise NotFoundException("Resident")
        if not resident.is_primary:
            raise ForbiddenException("Only the primary resident can make a community finance payment for the unit.")
        if not resident.unit_id:
            raise BadRequestException("Your resident account is not linked to a unit.")
        return resident

    @staticmethod
    def _validate_contribution_rule(mode: str, per_unit_amount):
        mode = mode.upper()
        if mode not in {"FIXED", "SUGGESTED", "FREE"}:
            raise BadRequestException("Contribution mode must be FIXED, SUGGESTED or FREE.")
        if mode in {"FIXED", "SUGGESTED"} and (per_unit_amount is None or Decimal(str(per_unit_amount)) <= 0):
            raise BadRequestException("Enter a positive per-house amount for FIXED or SUGGESTED contributions.")

    def _household_status(self, fund, households, contributions):
        """Return organization-wide primary-household payment status.

        FIXED collections are mandatory per house, so every active primary
        household is represented as PAID, PARTIAL or UNPAID.  SUGGESTED/FREE
        collections are voluntary; non-contributors are therefore shown as
        NOT_CONTRIBUTED rather than UNPAID.
        """
        verified = [c for c in contributions if c.status == "VERIFIED"]
        by_resident = {}
        by_unit = {}
        for c in verified:
            amount = Decimal(str(c.amount))
            if c.resident_id is not None:
                by_resident[c.resident_id] = by_resident.get(c.resident_id, Decimal("0")) + amount
            key = ((c.block_name or "").strip().lower(), (c.unit_number or "").strip().lower())
            if key[1]:
                by_unit[key] = by_unit.get(key, Decimal("0")) + amount

        result = []
        required = Decimal(str(fund.per_unit_amount)) if fund.per_unit_amount is not None else None
        for resident in households:
            paid = by_resident.get(resident.id, Decimal("0"))
            if paid == 0 and resident.unit_number:
                key = ((resident.section_name or "").strip().lower(), (resident.unit_number or "").strip().lower())
                paid = by_unit.get(key, Decimal("0"))

            if fund.contribution_mode == "FIXED":
                if required is not None and paid >= required:
                    status = "PAID"
                elif paid > 0:
                    status = "PARTIAL"
                else:
                    status = "UNPAID"
            else:
                status = "PAID" if paid > 0 else "NOT_CONTRIBUTED"

            result.append({
                "resident_id": resident.id,
                "resident_name": resident.full_name or "Resident",
                "section_name": resident.section_name,
                "unit_number": resident.unit_number,
                "required_amount": required if fund.contribution_mode == "FIXED" else fund.per_unit_amount,
                "amount_paid": paid,
                "status": status,
            })
        return result

    def _response(self, fund, viewer=None, households=None):
        collected = self.repo.contribution_total(fund.id)
        expenses = self.repo.expense_total(fund.id)
        raw_contributions = self.repo.contributions(fund.id)
        contributions = [
            {
                "id": c.id,
                "resident_id": c.resident_id,
                "payer_name": c.payer_name,
                "block_name": c.block_name,
                "unit_number": c.unit_number,
                "amount": c.amount,
                "payment_method": c.payment_method,
                "reference": c.reference,
                "status": c.status,
                "collected_at": c.collected_at,
            }
            for c in raw_contributions
            if viewer is None or viewer.role != "RESIDENT" or c.status == "VERIFIED"
        ]
        fund_expenses = [
            {
                "id": e.id,
                "category": e.category,
                "description": e.description,
                "amount": e.amount,
                "spent_on": e.spent_on,
                "created_at": e.created_at,
            }
            for e in self.repo.expenses(fund.id)
        ]
        return {
            "id": fund.id,
            "title": fund.title,
            "purpose": fund.purpose,
            "target_amount": fund.target_amount,
            "contribution_mode": fund.contribution_mode,
            "per_unit_amount": fund.per_unit_amount,
            "due_date": fund.due_date,
            "status": fund.status,
            "payment_method": fund.payment_method,
            "payment_upi_id": fund.payment_upi_id,
            "payment_display_name": fund.payment_display_name,
            "collected_amount": collected,
            "expense_amount": expenses,
            "balance": Decimal(str(collected)) - Decimal(str(expenses)),
            "contributor_count": self.repo.contributor_count(fund.id),
            "created_at": fund.created_at,
            "contributions": contributions,
            "household_status": self._household_status(fund, households or [], raw_contributions),
            "expenses": fund_expenses,
        }

    def dashboard(self, user):
        can_pay = False
        if user.role == "RESIDENT":
            try:
                resident = self._primary_resident(user)
                can_pay = bool(resident.is_primary)
            except (NotFoundException, ForbiddenException):
                can_pay = False
        funds = self.repo.funds(user.organization_id)
        if user.role == "RESIDENT":
            funds = [f for f in funds if f.status == "PUBLISHED"]

        households = (
            self.db.query(Resident)
            .join(User, Resident.user_id == User.id)
            .options(joinedload(Resident.user), joinedload(Resident.unit).joinedload(__import__("app.models.unit", fromlist=["Unit"]).Unit.section))
            .filter(
                User.organization_id == user.organization_id,
                Resident.is_primary.is_(True),
                Resident.is_active.is_(True),
                User.is_active.is_(True),
            )
            .order_by(Resident.id.asc())
            .all()
        )
        rows = [self._response(f, viewer=user, households=households) for f in funds]
        total_collected = sum((Decimal(str(r["collected_amount"])) for r in rows), Decimal("0"))
        total_expenses = sum((Decimal(str(r["expense_amount"])) for r in rows), Decimal("0"))
        return {
            "can_pay": can_pay,
            "funds": rows,
            "total_collected": total_collected,
            "total_expenses": total_expenses,
            "total_balance": total_collected - total_expenses,
        }

    def create_fund(self, user, data):
        self._check_manager(user)
        mode = data.contribution_mode.upper()
        self._validate_contribution_rule(mode, data.per_unit_amount)
        payment_method = data.payment_method.upper()
        if payment_method == "DIRECT_UPI":
            if not data.payment_upi_id or "@" not in data.payment_upi_id:
                raise BadRequestException("Enter a valid UPI ID for this community collection.")
            if not data.payment_display_name or not data.payment_display_name.strip():
                raise BadRequestException("Enter the receiver name for this community collection.")

        fund = CommunityFund(
            organization_id=user.organization_id,
            title=data.title.strip(),
            purpose=data.purpose.strip(),
            target_amount=data.target_amount,
            contribution_mode=mode,
            per_unit_amount=data.per_unit_amount,
            due_date=data.due_date,
            payment_method=payment_method,
            payment_upi_id=data.payment_upi_id.strip() if data.payment_upi_id else None,
            payment_display_name=data.payment_display_name.strip() if data.payment_display_name else None,
            created_by=user.id,
        )
        self.db.add(fund)
        self.db.flush()

        primary_residents = (
            self.db.query(Resident)
            .join(User, Resident.user_id == User.id)
            .filter(
                User.organization_id == user.organization_id,
                Resident.is_primary.is_(True),
                Resident.is_active.is_(True),
                User.is_active.is_(True),
            )
            .all()
        )
        if fund.status == "PUBLISHED":
            for resident in primary_residents:
                self.db.add(Notification(
                    user_id=resident.user_id,
                    title="New Community Collection",
                    message=(
                        f"{fund.title} collection is now open. Purpose: {fund.purpose}."
                        + (f" Target: ₹{fund.target_amount:.2f}." if fund.target_amount is not None else "")
                        + (f" Suggested per house: ₹{fund.per_unit_amount:.2f}." if fund.per_unit_amount is not None else "")
                    ),
                    notification_type="COMMUNITY_FINANCE",
                ))

        self.db.commit()
        self.db.refresh(fund)
        return self._response(fund)

    def update_fund(self, user, fund_id, data):
        self._check_manager(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        if fund.status == "CLOSED":
            raise BadRequestException("A closed community collection cannot be edited.")
        if self.repo.contribution_total(fund.id) > 0 or self.repo.contributions(fund.id) or self.repo.expenses(fund.id):
            raise BadRequestException("A collection with payment or expense activity cannot be edited.")
        mode = data.contribution_mode.upper()
        self._validate_contribution_rule(mode, data.per_unit_amount)
        payment_method = data.payment_method.upper()
        if payment_method == "DIRECT_UPI" and (not data.payment_upi_id or "@" not in data.payment_upi_id or not data.payment_display_name):
            raise BadRequestException("Enter a valid UPI ID and receiver name for Direct UPI.")
        fund.title = data.title.strip()
        fund.purpose = data.purpose.strip()
        fund.target_amount = data.target_amount
        fund.contribution_mode = mode
        fund.per_unit_amount = data.per_unit_amount
        fund.due_date = data.due_date
        fund.payment_method = payment_method
        fund.payment_upi_id = data.payment_upi_id.strip() if data.payment_upi_id else None
        fund.payment_display_name = data.payment_display_name.strip() if data.payment_display_name else None
        self.db.commit()
        return self._response(fund)

    def delete_fund(self, user, fund_id):
        self._check_manager(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        if self.repo.contribution_total(fund.id) > 0 or self.repo.contributions(fund.id) or self.repo.expenses(fund.id):
            raise BadRequestException("A collection with payment or expense activity cannot be deleted. Close it instead.")
        self.db.delete(fund)
        self.db.commit()
        return {"success": True, "fund_id": fund_id}

    def publish_fund(self, user, fund_id):
        self._check_manager(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        if fund.status == "CLOSED":
            raise BadRequestException("A closed community collection cannot be published.")
        fund.status = "PUBLISHED"
        primary_residents = (
            self.db.query(Resident)
            .join(User, Resident.user_id == User.id)
            .filter(User.organization_id == user.organization_id, Resident.is_primary.is_(True), Resident.is_active.is_(True), User.is_active.is_(True))
            .all()
        )
        for resident in primary_residents:
            self.db.add(Notification(
                user_id=resident.user_id,
                title="New Community Collection",
                message=(
                    f"{fund.title} collection is now open. Purpose: {fund.purpose}."
                    + (f" Target: ₹{fund.target_amount:.2f}." if fund.target_amount is not None else "")
                    + (f" Suggested per house: ₹{fund.per_unit_amount:.2f}." if fund.per_unit_amount is not None else "")
                ),
                notification_type="COMMUNITY_FINANCE",
            ))
        self.db.commit()
        return self._response(fund)

    def close_fund(self, user, fund_id):
        self._check_manager(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        fund.status = "CLOSED"
        self.db.commit()
        return self._response(fund)

    def add_contribution(self, user, fund_id, data):
        self._check_manager(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        self._validate_amount(fund, data.amount)
        row = CommunityFundContribution(
            fund_id=fund.id,
            resident_id=None,
            payer_name=data.payer_name.strip(),
            block_name=data.block_name.strip() if data.block_name else None,
            unit_number=data.unit_number.strip() if data.unit_number else None,
            amount=data.amount,
            payment_method=data.payment_method.upper(),
            reference=data.reference,
            status="VERIFIED",
            verified_at=__import__("datetime").datetime.utcnow(),
            verified_by=user.id,
            recorded_by=user.id,
        )
        self.db.add(row)
        self.db.commit()
        return self._response(fund)

    def _validate_amount(self, fund, amount):
        amount = Decimal(str(amount))
        if fund.contribution_mode == "FIXED" and amount != Decimal(str(fund.per_unit_amount)):
            raise BadRequestException(f"This collection requires exactly ₹{Decimal(str(fund.per_unit_amount)):.2f} per house.")
        if amount <= 0:
            raise BadRequestException("Contribution amount must be greater than zero.")

    def create_payment(self, user, fund_id, amount):
        resident = self._primary_resident(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        if fund.status != "PUBLISHED":
            raise BadRequestException("This community collection is not open for payment.")
        self._validate_amount(fund, amount)
        amount = Decimal(str(amount))
        reference_id = f"SAFE-CF-{fund.id}-{resident.id}-{int(time.time())}"
        if fund.payment_method == "DIRECT_UPI":
            if not fund.payment_upi_id or not fund.payment_display_name:
                raise BadRequestException("Direct UPI payment is not configured for this collection.")
            upi_url = (
                "upi://pay?"
                f"pa={quote(fund.payment_upi_id)}"
                f"&pn={quote(fund.payment_display_name)}"
                f"&am={quote(f'{amount:.2f}')}"
                "&cu=INR"
                f"&tn={quote(f'SafeColony community fund #{fund.id}')}"
            )
            return {
                "fund_id": fund.id,
                "amount": amount,
                "mode": "DIRECT_UPI",
                "reference_id": reference_id,
                "payment_url": upi_url,
                "upi_id": fund.payment_upi_id,
                "display_name": fund.payment_display_name,
                "message": "Complete the UPI payment and submit the UPI transaction reference. The finance administrator will verify it.",
            }
        return {
            "fund_id": fund.id,
            "amount": amount,
            "mode": "MANUAL",
            "reference_id": reference_id,
            "payment_url": "",
            "upi_id": None,
            "display_name": None,
            "message": "Pay by the community's manual method and submit the reference/receipt. The finance administrator will verify it.",
        }

    def submit_payment(self, user, fund_id, data):
        resident = self._primary_resident(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        if fund.status != "PUBLISHED":
            raise BadRequestException("This community collection is not open for payment.")
        self._validate_amount(fund, data.amount)
        if fund.payment_method == "DIRECT_UPI" and not data.reference:
            raise BadRequestException("Enter the UPI transaction reference after payment.")
        row = CommunityFundContribution(
            fund_id=fund.id,
            resident_id=resident.id,
            payer_name=resident.full_name or user.full_name,
            block_name=resident.section_name,
            unit_number=resident.unit_number,
            amount=data.amount,
            payment_method=fund.payment_method,
            reference=data.reference,
            status="PENDING",
            recorded_by=user.id,
        )
        self.db.add(row)
        self.db.flush()
        admins = self.db.query(User).filter(
            User.organization_id == user.organization_id,
            User.role.in_(["ORGANIZATION_ADMIN", "COMMUNITY_FINANCE_ADMIN"]),
            User.is_active.is_(True),
        ).all()
        for admin in admins:
            self.db.add(Notification(
                user_id=admin.id,
                title="Community Payment Verification Required",
                message=f"{resident.full_name or user.full_name} submitted ₹{data.amount:.2f} for {fund.title}. Reference: {data.reference or 'Not provided'}.",
                notification_type="COMMUNITY_FINANCE_PAYMENT",
            ))
        self.db.commit()
        return self._response(fund)

    def verify_contribution(self, user, contribution_id, approve):
        self._check_manager(user)
        contribution = self.repo.get_contribution(contribution_id, user.organization_id)
        if not contribution:
            raise NotFoundException("Community contribution")
        if contribution.status != "PENDING":
            raise BadRequestException("This contribution has already been processed.")
        contribution.status = "VERIFIED" if approve else "REJECTED"
        contribution.verified_by = user.id
        contribution.verified_at = __import__("datetime").datetime.utcnow()
        self.db.commit()
        return {"success": True, "status": contribution.status, "fund_id": contribution.fund_id}

    def add_expense(self, user, fund_id, data):
        self._check_manager(user)
        fund = self.repo.get_fund(fund_id, user.organization_id)
        if not fund:
            raise NotFoundException("Community fund")
        row = CommunityFundExpense(fund_id=fund.id, category=data.category.strip(), description=data.description.strip(), amount=data.amount, spent_on=data.spent_on, created_by=user.id)
        self.db.add(row)
        self.db.commit()
        return self._response(fund)
