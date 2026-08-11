from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class MaintenancePeriodCreate(BaseModel):
    month: date
    monthly_amount: Decimal = Field(gt=0)
    due_date: date
    notes: str | None = None


class MaintenanceExpenseCreate(BaseModel):
    category: str = Field(min_length=2, max_length=60)
    description: str = Field(min_length=2, max_length=500)
    amount: Decimal = Field(gt=0)
    spent_on: date


class MaintenancePaymentCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    payment_method: str = Field(default="MANUAL", min_length=2, max_length=30)
    reference: str | None = Field(default=None, max_length=100)


class MaintenanceBillResponse(BaseModel):
    id: int
    period_id: int
    resident_id: int
    resident_name: str
    property_name: str | None
    section_name: str | None
    unit_number: str | None
    amount: Decimal
    carried_forward: Decimal
    late_fee: Decimal
    total_due: Decimal
    amount_paid: Decimal
    balance: Decimal
    due_date: date
    status: str
    paid_at: datetime | None
    model_config = ConfigDict(from_attributes=True)


class MaintenanceExpenseResponse(BaseModel):
    id: int
    period_id: int
    category: str
    description: str
    amount: Decimal
    spent_on: date
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class MaintenancePeriodResponse(BaseModel):
    id: int
    organization_id: int
    month: date
    monthly_amount: Decimal
    due_date: date
    opening_balance: Decimal
    billed_total: Decimal
    collected_total: Decimal
    expense_total: Decimal
    closing_balance: Decimal
    total_bills: int
    paid_bills: int
    unpaid_bills: int
    notes: str | None


class MaintenanceDashboardResponse(BaseModel):
    period: MaintenancePeriodResponse | None
    bills: list[MaintenanceBillResponse]
    expenses: list[MaintenanceExpenseResponse]


class ResidentMaintenanceSummary(BaseModel):
    bill: MaintenanceBillResponse | None
    history: list[MaintenanceBillResponse]
