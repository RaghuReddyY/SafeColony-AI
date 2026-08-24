from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class OrganizationMaintenanceSectionSummary(BaseModel):
    section_id: int | None
    section_name: str
    month: date | None
    status: str | None
    opening_balance: Decimal
    billed_total: Decimal
    collected_total: Decimal
    expense_total: Decimal
    outstanding_total: Decimal
    balance: Decimal
    total_bills: int
    paid_bills: int
    pending_bills: int


class OrganizationCommunityFundSummary(BaseModel):
    id: int
    title: str
    status: str
    contribution_mode: str
    per_unit_amount: Decimal | None
    target_amount: Decimal | None
    collected_amount: Decimal
    expense_amount: Decimal
    balance: Decimal
    contributor_count: int
    paid_households: int
    pending_households: int


class OrganizationFinanceSummaryResponse(BaseModel):
    organization_name: str | None
    organization_code: str | None
    maintenance_billed_total: Decimal
    maintenance_collected_total: Decimal
    maintenance_expense_total: Decimal
    maintenance_outstanding_total: Decimal
    maintenance_balance: Decimal
    community_target_total: Decimal
    community_collected_total: Decimal
    community_expense_total: Decimal
    community_balance: Decimal
    community_fund_count: int
    maintenance_sections: list[OrganizationMaintenanceSectionSummary]
    community_funds: list[OrganizationCommunityFundSummary]


class MoneyTransactionResponse(BaseModel):
    id: str
    kind: str
    title: str
    payer_or_category: str
    block_name: str | None = None
    unit_number: str | None = None
    amount: Decimal
    status: str
    payment_method: str | None = None
    reference: str | None = None
    occurred_at: str
