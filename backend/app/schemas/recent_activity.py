from pydantic import BaseModel


class RecentActivityResponse(BaseModel):
    icon: str
    title: str
    time: str