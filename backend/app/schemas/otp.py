from pydantic import BaseModel, Field


class OTPRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)


class OTPRequestResponse(BaseModel):
    message: str
    expires_in: int
    dev_otp: str | None = None


class OTPVerifyRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    otp: str = Field(min_length=4, max_length=8)
