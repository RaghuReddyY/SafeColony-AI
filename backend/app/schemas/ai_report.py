from pydantic import BaseModel, Field


class AIReportRequest(BaseModel):
    report_type: str = Field(default="DAILY", pattern="^(DAILY|SECURITY|COMMUNITY|RESIDENT|GUARD|FINANCE)$")


class AIReportResponse(BaseModel):
    report_type: str
    title: str
    content: str
    generated_at: str
