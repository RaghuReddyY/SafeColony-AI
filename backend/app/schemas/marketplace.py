from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field


class VendorCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    category: str = Field(min_length=2, max_length=60)
    phone: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=1000)
    user_id: int | None = None


class VendorResponse(BaseModel):
    id: int
    name: str
    category: str
    phone: str | None
    notes: str | None
    is_active: bool
    user_id: int | None
    model_config = ConfigDict(from_attributes=True)


class VendorAccountCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    category: str = Field(min_length=2, max_length=60)
    phone: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=1000)
    full_name: str = Field(min_length=3, max_length=100)
    email: str
    password: str = Field(min_length=8, max_length=128)

class VendorAccountResponse(VendorResponse):
    email: str | None = None
    user_full_name: str | None = None
    user_active: bool | None = None


class EventCreate(BaseModel):
    title: str = Field(min_length=2, max_length=160)
    category: str = Field(min_length=2, max_length=60)
    event_type: str = Field(default="PRODUCT", pattern="^(PRODUCT|SERVICE)$")
    description: str | None = None
    vendor_id: int | None = None
    cutoff_at: datetime | None = None
    scheduled_for: datetime | None = None
    delivery_mode: str = "COMMUNITY_DROP"


class EventResponse(BaseModel):
    id: int
    title: str
    category: str
    event_type: str
    description: str | None
    vendor_id: int | None
    vendor_name: str | None = None
    cutoff_at: datetime | None
    scheduled_for: datetime | None
    delivery_mode: str
    status: str
    order_count: int = 0
    apartment_count: int = 0
    model_config = ConfigDict(from_attributes=True)


class OrderItemCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    quantity: Decimal = Field(gt=0)
    unit: str = Field(default="unit", max_length=30)
    unit_price: Decimal = Field(default=Decimal("0"), ge=0)


class OrderCreate(BaseModel):
    items: list[OrderItemCreate] = Field(min_length=1)
    delivery_mode: str = "COMMUNITY_DROP"
    notes: str | None = None
    service_slot: str | None = Field(default=None, max_length=80)
    payment_reference: str | None = Field(default=None, max_length=120)


class OrderItemResponse(BaseModel):
    name: str
    quantity: Decimal
    unit: str
    unit_price: Decimal


class OrderResponse(BaseModel):
    id: int
    event_id: int
    event_title: str
    resident_name: str
    status: str
    payment_status: str
    delivery_mode: str
    total_amount: Decimal
    notes: str | None
    service_slot: str | None = None
    payment_reference: str | None = None
    items: list[OrderItemResponse]


class AggregateItem(BaseModel):
    name: str
    quantity: Decimal
    unit: str
    order_count: int


class EventStatusUpdate(BaseModel):
    status: str = Field(pattern="^(OPEN|CLOSED|COMPLETED|CANCELLED)$")


class EventAggregateResponse(BaseModel):
    event_id: int
    event_title: str
    apartment_count: int
    order_count: int
    total_amount: Decimal
    items: list[AggregateItem]


class VendorDashboardResponse(BaseModel):
    vendor_id: int
    vendor_name: str
    category: str
    phone: str | None
    active: bool
    open_events: int
    upcoming_events: int
    total_orders: int
    pending_orders: int
    ready_orders: int
    delivered_orders: int
    total_sales: Decimal
    average_rating: float = 0
    rating_count: int = 0


class VendorEventResponse(EventResponse):
    total_amount: Decimal = Decimal("0")


class VendorProfileUpdate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    category: str = Field(min_length=2, max_length=60)
    phone: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=1000)


class VendorOfferCreate(BaseModel):
    event_id: int | None = None
    title: str = Field(min_length=2, max_length=160)
    description: str | None = None
    discount_percent: Decimal = Field(default=0, ge=0, le=100)
    min_orders: int = Field(default=1, ge=1)

class VendorOfferResponse(BaseModel):
    id: int
    vendor_id: int
    event_id: int | None
    title: str
    description: str | None
    discount_percent: Decimal
    min_orders: int
    is_active: bool
    model_config = ConfigDict(from_attributes=True)
