from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class MaintenancePeriodCreate(BaseModel):
    section_id: int | None = None
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


class MaintenancePaymentLinkResponse(BaseModel):
    bill_id: int
    amount: Decimal
    mode: str
    reference_id: str
    payment_link_id: str | None = None
    payment_url: str = ""
    expires_at: int | None = None
    upi_id: str | None = None
    display_name: str | None = None
    payment_phone: str | None = None
    message: str | None = None


class MaintenancePaymentSettings(BaseModel):
    late_fee_type: str = "NONE"
    late_fee_value: Decimal = Decimal("0.00")
    late_fee_grace_days: int = 0
    mode: str
    upi_id: str | None = None
    display_name: str | None = None
    payment_phone: str | None = None


class MaintenancePaymentSettingsUpdate(BaseModel):
    mode: str = Field(default="RAZORPAY", pattern="^(RAZORPAY|DIRECT_UPI)$")
    upi_id: str | None = Field(default=None, max_length=120)
    display_name: str | None = Field(default=None, max_length=150)
    payment_phone: str | None = Field(default=None, max_length=20)
    late_fee_type: str = Field(default="NONE", pattern="^(NONE|FLAT|PERCENT_PER_MONTH|PER_DAY)$")
    late_fee_value: Decimal = Field(default=Decimal("0.00"), ge=0)
    late_fee_grace_days: int = Field(default=0, ge=0, le=365)


class DirectUPIPaymentCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    reference: str = Field(min_length=4, max_length=100)


class MaintenancePendingPaymentResponse(BaseModel):
    id: int
    bill_id: int
    resident_id: int
    resident_name: str
    unit_number: str | None
    amount: Decimal
    reference: str | None
    payment_method: str
    status: str
    paid_at: datetime


class MaintenanceBillUpdate(BaseModel):
    amount: Decimal = Field(gt=0)
    due_date: date


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
    section_id: int | None
    month: date
    monthly_amount: Decimal
    due_date: date
    status: str = "DRAFT"
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
    is_primary: bool = True


class MaintenancePayerUpdate(BaseModel):
    resident_id: int = Field(gt=0)


class MaintenancePayerResident(BaseModel):
    id: int
    full_name: str
    resident_type: str
    is_primary: bool


class MaintenancePayerResponse(BaseModel):
    current_payer_resident_id: int | None
    current_payer_name: str | None
    current_payer_type: str | None
    eligible_residents: list[MaintenancePayerResident]


class MaintenanceInvoiceResponse(BaseModel):
    bill_id: int
    invoice_number: str
    resident_name: str
    unit_number: str | None
    billing_month: date
    issue_date: date
    due_date: date
    maintenance_amount: Decimal
    carried_forward: Decimal
    late_fee: Decimal
    total_due: Decimal
    amount_paid: Decimal
    balance: Decimal


class MaintenanceReceiptResponse(BaseModel):
    receipt_number: str
    payment_id: int
    bill_id: int
    resident_name: str
    unit_number: str | None
    amount: Decimal
    payment_method: str
    reference: str | None
    paid_at: datetime
    status: str
