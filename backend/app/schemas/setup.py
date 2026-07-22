from pydantic import BaseModel, EmailStr, Field


class SetupRequest(BaseModel):
    full_name: str = Field(..., min_length=3, max_length=100)
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=20)
    password: str = Field(..., min_length=8)


class SetupResponse(BaseModel):
    message: str
    user_id: int
    email: str
    role: str


class SetupStatusResponse(BaseModel):
    initialized: bool