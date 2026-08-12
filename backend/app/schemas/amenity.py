from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class AmenityCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    amenity_type: str = Field(min_length=2, max_length=50)
    description: str | None = Field(default=None, max_length=5000)
    location: str | None = Field(default=None, max_length=200)
    capacity: int | None = Field(default=None, gt=0)
    booking_required: bool = True
    approval_required: bool = True
    opening_time: str | None = Field(default=None, max_length=10)
    closing_time: str | None = Field(default=None, max_length=10)


class AmenityUpdate(AmenityCreate):
    is_active: bool = True


class AmenityResponse(AmenityCreate):
    id: int
    organization_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)


class AmenityBookingCreate(BaseModel):
    amenity_id: int
    start_at: datetime
    end_at: datetime
    purpose: str | None = Field(default=None, max_length=300)


class AmenityBookingDecision(BaseModel):
    approve: bool
    reason: str | None = Field(default=None, max_length=500)


class AmenityBookingResponse(BaseModel):
    id: int
    amenity_id: int
    resident_id: int
    created_by_user_id: int
    start_at: datetime
    end_at: datetime
    purpose: str | None
    status: str
    approved_by_user_id: int | None
    approved_at: datetime | None
    rejection_reason: str | None
    cancelled_at: datetime | None
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
