from datetime import datetime
from typing import Any

from pydantic import BaseModel


class AIInsightCard(BaseModel):
    key: str
    title: str
    category: str
    summary: str
    details: list[str]
    action: str | None = None
    priority: str = "NORMAL"


class AIFutureFeature(BaseModel):
    key: str
    title: str
    status: str
    description: str


class AIOverviewResponse(BaseModel):
    role: str
    generated_at: datetime
    metrics: dict[str, Any]
    insights: list[AIInsightCard]
    future_features: list[AIFutureFeature]
