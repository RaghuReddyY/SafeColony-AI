from typing import Literal

from pydantic import BaseModel, Field


class AIChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=4000)


class AIChatRequest(BaseModel):
    messages: list[AIChatMessage] = Field(min_length=1, max_length=20)
    language: str | None = Field(default=None, max_length=20)


class AIChatResponse(BaseModel):
    message: str


class AIIntentRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)

class AIIntentResponse(BaseModel):
    intent: str
    category: str | None = None
    action: str | None = None
    requires_confirmation: bool = True
    explanation: str


class AIActionRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    confirmed: bool = False
    event_id: int | None = None
    items: list[dict] | None = None
    service_request: dict | None = None

class AIActionResponse(BaseModel):
    intent: str
    action: str
    requires_confirmation: bool
    preview: str
    result: dict | None = None
