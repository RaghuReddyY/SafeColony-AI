from decimal import Decimal
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.community_fund import CommunityFund, CommunityFundContribution, CommunityFundExpense
from app.models.resident import Resident


class CommunityFinanceRepository:
    def __init__(self, db: Session):
        self.db = db

    def funds(self, organization_id: int):
        return (
            self.db.query(CommunityFund)
            .filter(CommunityFund.organization_id == organization_id)
            .order_by(CommunityFund.created_at.desc())
            .all()
        )

    def get_fund(self, fund_id: int, organization_id: int):
        return (
            self.db.query(CommunityFund)
            .filter(CommunityFund.id == fund_id, CommunityFund.organization_id == organization_id)
            .first()
        )

    def contribution_total(self, fund_id: int):
        return self.db.query(func.coalesce(func.sum(CommunityFundContribution.amount), 0)).filter(
            CommunityFundContribution.fund_id == fund_id,
            CommunityFundContribution.status == "VERIFIED",
        ).scalar() or Decimal("0")

    def expense_total(self, fund_id: int):
        return self.db.query(func.coalesce(func.sum(CommunityFundExpense.amount), 0)).filter(CommunityFundExpense.fund_id == fund_id).scalar() or Decimal("0")

    def contributor_count(self, fund_id: int):
        return self.db.query(func.count(CommunityFundContribution.id)).filter(
            CommunityFundContribution.fund_id == fund_id,
            CommunityFundContribution.status == "VERIFIED",
        ).scalar() or 0

    def contributions(self, fund_id: int):
        return (
            self.db.query(CommunityFundContribution)
            .filter(CommunityFundContribution.fund_id == fund_id)
            .order_by(CommunityFundContribution.collected_at.desc(), CommunityFundContribution.id.desc())
            .all()
        )

    def expenses(self, fund_id: int):
        return (
            self.db.query(CommunityFundExpense)
            .filter(CommunityFundExpense.fund_id == fund_id)
            .order_by(CommunityFundExpense.spent_on.desc(), CommunityFundExpense.id.desc())
            .all()
        )

    def get_contribution(self, contribution_id: int, organization_id: int):
        return (
            self.db.query(CommunityFundContribution)
            .join(CommunityFund, CommunityFund.id == CommunityFundContribution.fund_id)
            .filter(
                CommunityFundContribution.id == contribution_id,
                CommunityFund.organization_id == organization_id,
            )
            .first()
        )
