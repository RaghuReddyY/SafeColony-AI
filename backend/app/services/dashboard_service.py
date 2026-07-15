from fastapi import HTTPException


class DashboardService:

    def __init__(self, repo):
        self.repo = repo

    def get_summary(self, resident_id: int):

        summary = self.repo.get_summary(resident_id)

        if summary is None:
            raise HTTPException(
                status_code=404,
                detail="Resident not found",
            )

        return summary