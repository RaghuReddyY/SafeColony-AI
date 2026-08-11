from typing import Literal

from pydantic import BaseModel, Field


class AIChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=4000)


class AIChatRequest(BaseModel):
    messages: list[AIChatMessage] = Field(min_length=1, max_length=20)


class AIChatResponse(BaseModel):
    message: str
