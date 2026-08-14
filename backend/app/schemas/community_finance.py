from datetime import date, datetime
from decimal import Decimal
from pydantic import BaseModel, Field


class CommunityFundCreate(BaseModel):
    title: str = Field(min_length=3, max_length=150)
    purpose: str = Field(min_length=3, max_length=1000)
    target_amount: Decimal | None = Field(default=None, gt=0)
    contribution_mode: str = Field(default="FREE", pattern="^(FIXED|SUGGESTED|FREE)$")
    per_unit_amount: Decimal | None = Field(default=None, gt=0)
    due_date: date | None = None
    payment_method: str = Field(default="MANUAL", pattern="^(MANUAL|DIRECT_UPI)$")
    payment_upi_id: str | None = Field(default=None, max_length=120)
    payment_display_name: str | None = Field(default=None, max_length=150)
    status: str = Field(default="PUBLISHED", pattern="^(DRAFT|PUBLISHED)$")


class CommunityFundUpdate(BaseModel):
    title: str = Field(min_length=3, max_length=150)
    purpose: str = Field(min_length=3, max_length=1000)
    target_amount: Decimal | None = Field(default=None, gt=0)
    contribution_mode: str = Field(default="FREE", pattern="^(FIXED|SUGGESTED|FREE)$")
    per_unit_amount: Decimal | None = Field(default=None, gt=0)
    due_date: date | None = None
    payment_method: str = Field(default="MANUAL", pattern="^(MANUAL|DIRECT_UPI)$")
    payment_upi_id: str | None = Field(default=None, max_length=120)
    payment_display_name: str | None = Field(default=None, max_length=150)


class CommunityFundContributionCreate(BaseModel):
    payer_name: str = Field(min_length=2, max_length=120)
    block_name: str | None = Field(default=None, max_length=100)
    unit_number: str | None = Field(default=None, max_length=50)
    amount: Decimal = Field(gt=0)
    payment_method: str = Field(default="MANUAL", min_length=2, max_length=30)
    reference: str | None = Field(default=None, max_length=100)


class CommunityFundResidentPaymentCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    reference: str | None = Field(default=None, max_length=100)


class CommunityFundExpenseCreate(BaseModel):
    category: str = Field(min_length=2, max_length=60)
    description: str = Field(min_length=2, max_length=500)
    amount: Decimal = Field(gt=0)
    spent_on: date


class CommunityFundContributionResponse(BaseModel):
    id: int
    resident_id: int | None
    payer_name: str
    block_name: str | None
    unit_number: str | None
    amount: Decimal
    payment_method: str
    reference: str | None
    status: str
    collected_at: datetime


class CommunityFundExpenseResponse(BaseModel):
    id: int
    category: str
    description: str
    amount: Decimal
    spent_on: date
    created_at: datetime


class CommunityFundPaymentLinkResponse(BaseModel):
    fund_id: int
    amount: Decimal
    mode: str
    reference_id: str
    payment_url: str = ""
    upi_id: str | None = None
    display_name: str | None = None
    message: str | None = None


class CommunityFundHouseholdStatusResponse(BaseModel):
    resident_id: int
    resident_name: str
    section_name: str | None
    unit_number: str | None
    required_amount: Decimal | None
    amount_paid: Decimal
    status: str


class CommunityFundResponse(BaseModel):
    id: int
    title: str
    purpose: str
    target_amount: Decimal | None
    contribution_mode: str
    per_unit_amount: Decimal | None
    due_date: date | None
    status: str
    payment_method: str
    payment_upi_id: str | None
    payment_display_name: str | None
    collected_amount: Decimal
    expense_amount: Decimal
    balance: Decimal
    contributor_count: int
    created_at: datetime
    contributions: list[CommunityFundContributionResponse] = Field(default_factory=list)
    household_status: list[CommunityFundHouseholdStatusResponse] = Field(default_factory=list)
    expenses: list[CommunityFundExpenseResponse] = Field(default_factory=list)


class CommunityFinanceDashboardResponse(BaseModel):
    can_pay: bool = False
    funds: list[CommunityFundResponse]
    total_collected: Decimal
    total_expenses: Decimal
    total_balance: Decimal
