from fastapi import HTTPException


class BaseService:

    def __init__(self, repo):
        self.repo = repo

    def get_all(self):
        return self.repo.get_all()

    def get_by_id(self, id):

        obj = self.repo.get_by_id(id)

        if obj is None:
            raise HTTPException(
                404,
                "Record not found"
            )

        return obj