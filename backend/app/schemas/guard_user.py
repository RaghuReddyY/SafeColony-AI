from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ==========================================================
# Create Guard
# ==========================================================

class GuardCreate(BaseModel):

    full_name: str = Field(..., max_length=100)

    email: EmailStr

    phone: str = Field(..., max_length=20)

    password: str = Field(..., min_length=6)


# ==========================================================
# Guard Response
# ==========================================================

class GuardResponse(BaseModel):

    id: int

    full_name: str

    email: str

    phone: str

    role: str

    status: str

    is_active: bool

    model_config = ConfigDict(
        from_attributes=True
    )