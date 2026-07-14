from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DeliveryCreate(BaseModel):

    resident_id: int

    courier_name: str

    tracking_number: str | None = None

    package_type: str


class DeliveryResponse(BaseModel):

    id: int

    resident_id: int

    courier_name: str

    tracking_number: str | None

    package_type: str

    status: str

    received_by: str | None

    delivered_at: datetime | None

    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )