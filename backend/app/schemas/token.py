from typing import Optional

from pydantic import BaseModel


class Token(BaseModel):
    access_token: str
    token_type: str

    resident_status: Optional[str] = None
    user_status: Optional[str] = None