from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.enums.delivery_policy import DeliveryPolicy
from app.enums.vacation_status import VacationStatus
from app.enums.visitor_policy import VisitorPolicy


# =====================================================
# Create Vacation Mode
# =====================================================

class VacationModeCreate(BaseModel):

    resident_id: int = Field(..., description="Resident ID")

    start_date: date = Field(..., description="Vacation start date")

    end_date: date = Field(..., description="Vacation end date")

    reason: str | None = Field(
        default=None,
        max_length=200,
        description="Reason for vacation",
    )

    emergency_contact: str | None = Field(
        default=None,
        max_length=20,
        description="Emergency contact number",
    )

    visitor_policy: VisitorPolicy = Field(
        default=VisitorPolicy.REJECT_ALL,
        description="Visitor handling policy",
    )

    delivery_policy: DeliveryPolicy = Field(
        default=DeliveryPolicy.ALLOW,
        description="Delivery handling policy",
    )

    notify_security: bool = Field(
        default=True,
        description="Notify security when vacation starts",
    )

    monitoring_enabled: bool = Field(
        default=True,
        description="Enable monitoring while resident is away",
    )


# =====================================================
# Update Vacation Mode
# =====================================================

class VacationModeUpdate(BaseModel):

    start_date: date | None = None

    end_date: date | None = None

    reason: str | None = Field(
        default=None,
        max_length=200,
    )

    emergency_contact: str | None = Field(
        default=None,
        max_length=20,
    )

    visitor_policy: VisitorPolicy | None = None

    delivery_policy: DeliveryPolicy | None = None

    notify_security: bool | None = None

    monitoring_enabled: bool | None = None


# =====================================================
# Vacation Response
# =====================================================

class VacationModeResponse(BaseModel):

    id: int

    resident_id: int

    start_date: date

    end_date: date

    reason: str | None = None

    emergency_contact: str | None = None

    visitor_policy: VisitorPolicy

    delivery_policy: DeliveryPolicy

    notify_security: bool

    monitoring_enabled: bool

    status: VacationStatus

    activated_at: datetime | None = None

    deactivated_at: datetime | None = None

    created_at: datetime

    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )


# =====================================================
# Guard Dashboard Response
# =====================================================

class ActiveVacationResponse(BaseModel):

    resident_name: str

    unit_number: str

    start_date: date

    end_date: date

    visitor_policy: VisitorPolicy

    delivery_policy: DeliveryPolicy

    emergency_contact: str | None = None

    days_remaining: int


# =====================================================
# Vacation Summary Response
# =====================================================

class VacationSummaryResponse(BaseModel):

    total_active: int

    total_scheduled: int

    total_completed: int

    total_cancelled: int