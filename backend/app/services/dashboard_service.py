from fastapi import HTTPException


class DashboardService:

    def __init__(self, repo):
        self.repo = repo

    def get_summary(self, user_id: int):
        """
        user_id comes from the logged-in JWT user.
        Repository will internally find the corresponding Resident.
        """

        summary = self.repo.get_summary(user_id)

        if summary is None:
            raise HTTPException(
                status_code=404,
                detail="Resident profile not found for this user.",
            )

        return summary