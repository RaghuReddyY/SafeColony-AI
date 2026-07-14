from fastapi import HTTPException


class SecurityAlertService:

    def __init__(self, repo):

        self.repo = repo

    def get_all(self):

        return self.repo.get_all()

    def get_unresolved(self):

        return self.repo.get_unresolved()

    def resolve(self, alert_id: int):

        alert = self.repo.get_by_id(alert_id)

        if alert is None:

            raise HTTPException(
                status_code=404,
                detail="Alert not found",
            )

        alert.is_resolved = True

        return self.repo.save(alert)