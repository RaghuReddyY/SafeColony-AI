from datetime import datetime

from pydantic import BaseModel, ConfigDict


# --------------------------------------------------
# Create Delivery
# --------------------------------------------------

class DeliveryCreate(BaseModel):

    resident_id: int

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
# Delivery Response
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

    created_at: datetime

    collected_at: datetime | None

    model_config = ConfigDict(
        from_attributes=True
    )