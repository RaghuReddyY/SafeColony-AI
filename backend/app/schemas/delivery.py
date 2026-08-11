from datetime import datetime

from pydantic import BaseModel, ConfigDict


# --------------------------------------------------
# Common delivery fields
# --------------------------------------------------

class DeliveryCreate(BaseModel):
    """Used by Admin/Guard flows where resident_id is selected."""

    resident_id: int
    courier_name: str
    delivery_category: str
    tracking_number: str | None = None
    package_photo: str | None = None
    priority: str = "NORMAL"


class ResidentDeliveryCreate(BaseModel):
    """Used by a logged-in resident for their own delivery."""

    courier_name: str
    delivery_category: str
    tracking_number: str | None = None
    package_photo: str | None = None
    priority: str = "NORMAL"


# --------------------------------------------------
# OTP Verification
# --------------------------------------------------

class VerifyOtpRequest(BaseModel):
    otp: str


# --------------------------------------------------
# Resident/Admin Response
# --------------------------------------------------

class DeliveryResponse(BaseModel):
    id: int
    resident_id: int
    courier_name: str
    tracking_number: str | None
    delivery_category: str
    package_photo: str | None
    priority: str
    status: str
    received_by: str | None
    otp: str | None = None
    created_at: datetime
    collected_at: datetime | None

    model_config = ConfigDict(
        from_attributes=True
    )


# --------------------------------------------------
# Guard Response
# --------------------------------------------------
# IMPORTANT: Do not expose the resident OTP to guard list APIs.
# The guard asks the resident for the OTP and enters it during
# collection.

class GuardDeliveryResponse(BaseModel):
    id: int
    resident_id: int
    courier_name: str
    tracking_number: str | None
    delivery_category: str
    package_photo: str | None
    priority: str
    status: str
    received_by: str | None
    created_at: datetime
    collected_at: datetime | None

    model_config = ConfigDict(
        from_attributes=True
    )
