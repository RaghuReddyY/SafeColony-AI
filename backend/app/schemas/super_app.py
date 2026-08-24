from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field


class ServiceProviderResponse(BaseModel):
    id: int
    provider_type: str
    name: str
    category: str
    phone: str | None = None
    description: str | None = None
    vendor_id: int | None = None
    provider_id: int | None = None


class ServiceRequestCreate(BaseModel):
    category: str = Field(min_length=2, max_length=60)
    title: str = Field(min_length=2, max_length=160)
    description: str | None = None
    preferred_slot: str | None = Field(default=None, max_length=100)
    provider_id: int | None = None
    vendor_id: int | None = None


class ServiceRequestResponse(BaseModel):
    id: int
    category: str
    title: str
    description: str | None
    preferred_slot: str | None
    status: str
    quoted_amount: Decimal | None
    payment_status: str
    provider_id: int | None = None
    provider_name: str | None = None
    vendor_id: int | None = None
    vendor_name: str | None = None
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class ServiceStatusUpdate(BaseModel):
    status: str = Field(pattern="^(REQUESTED|ASSIGNED|QUOTED|APPROVED|IN_PROGRESS|COMPLETED|CANCELLED)$")
    quoted_amount: Decimal | None = Field(default=None, ge=0)


class OfferCreate(BaseModel):
    vendor_id: int
    event_id: int | None = None
    title: str = Field(min_length=2, max_length=160)
    description: str | None = None
    discount_percent: Decimal = Field(default=0, ge=0, le=100)
    min_orders: int = Field(default=1, ge=1)


class OfferResponse(BaseModel):
    id: int
    vendor_id: int
    event_id: int | None
    title: str
    description: str | None
    discount_percent: Decimal
    min_orders: int
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


class RatingCreate(BaseModel):
    vendor_id: int
    order_id: int | None = None
    rating: int = Field(ge=1, le=5)
    quality: int | None = Field(default=None, ge=1, le=5)
    price: int | None = Field(default=None, ge=1, le=5)
    delivery: int | None = Field(default=None, ge=1, le=5)
    comment: str | None = None


class RatingResponse(BaseModel):
    id: int
    vendor_id: int
    rating: int
    quality: int | None
    price: int | None
    delivery: int | None
    comment: str | None
    model_config = ConfigDict(from_attributes=True)


class ParcelCreate(BaseModel):
    order_id: int
    apartment_label: str = Field(min_length=1, max_length=80)
    hub: str = Field(default="Main Gate", max_length=120)


class ParcelResponse(BaseModel):
    id: int
    order_id: int
    apartment_label: str
    hub: str
    pickup_code: str
    status: str
    created_at: datetime | None = None
    model_config = ConfigDict(from_attributes=True)


class RecurringOrderCreate(BaseModel):
    category: str = Field(min_length=2, max_length=60)
    description: str = Field(min_length=2, max_length=255)
    cadence: str = Field(default="WEEKLY", max_length=40)
    preferred_day: str | None = None
    preferred_slot: str | None = None


class RecurringOrderResponse(BaseModel):
    id: int
    category: str
    description: str
    cadence: str
    preferred_day: str | None
    preferred_slot: str | None
    active: bool
    model_config = ConfigDict(from_attributes=True)


class UtilityProviderCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    utility_type: str = Field(min_length=2, max_length=40)
    integration_type: str = Field(default="MANUAL", max_length=30)
    status: str = Field(default="ONBOARDING", pattern="^(ONBOARDING|ACTIVE|INACTIVE)$")
    contact_name: str | None = Field(default=None, max_length=100)
    contact_email: str | None = Field(default=None, max_length=120)
    contact_phone: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=1000)


class UtilityProviderUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    utility_type: str | None = Field(default=None, min_length=2, max_length=40)
    integration_type: str | None = Field(default=None, max_length=30)
    status: str | None = Field(default=None, pattern="^(ONBOARDING|ACTIVE|INACTIVE)$")
    contact_name: str | None = Field(default=None, max_length=100)
    contact_email: str | None = Field(default=None, max_length=120)
    contact_phone: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=1000)
    is_active: bool | None = None


class UtilityProviderResponse(BaseModel):
    id: int
    name: str
    utility_type: str
    integration_type: str
    status: str
    contact_name: str | None
    contact_email: str | None
    contact_phone: str | None
    notes: str | None
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


class MapPointCreate(BaseModel):
    point_type: str = Field(min_length=2, max_length=40)
    name: str = Field(min_length=2, max_length=120)
    description: str | None = None
    address: str | None = Field(default=None, max_length=255)
    latitude: Decimal = Field(ge=Decimal("-90"), le=Decimal("90"))
    longitude: Decimal = Field(ge=Decimal("-180"), le=Decimal("180"))


class MapPointUpdate(BaseModel):
    point_type: str | None = Field(default=None, min_length=2, max_length=40)
    name: str | None = Field(default=None, min_length=2, max_length=120)
    description: str | None = None
    address: str | None = Field(default=None, max_length=255)
    latitude: Decimal | None = Field(default=None, ge=Decimal("-90"), le=Decimal("90"))
    longitude: Decimal | None = Field(default=None, ge=Decimal("-180"), le=Decimal("180"))
    is_active: bool | None = None


class MapPointResponse(BaseModel):
    id: int
    point_type: str
    name: str
    description: str | None
    address: str | None
    latitude: Decimal
    longitude: Decimal
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


class HubSummaryResponse(BaseModel):
    total_parcels: int
    at_hub: int
    picked_up: int
    pending_requests: int
    active_recurring_orders: int


class SuperAppOverviewResponse(BaseModel):
    role: str
    services: list[dict]
    marketplace_categories: list[str]
    upcoming_community_days: list[dict]
    hub: HubSummaryResponse
    utilities: list[dict]
    supported_utility_providers: list[UtilityProviderResponse]
    map_points: list[MapPointResponse]
