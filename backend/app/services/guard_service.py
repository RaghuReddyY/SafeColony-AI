class GuardService:

    def __init__(self, repo):
        self.repo = repo

    def dashboard(self):

        return {

            "pending_visitors":
                self.repo.count_by_status("PENDING"),

            "approved_visitors":
                self.repo.count_by_status("APPROVED"),

            "checked_in":
                self.repo.count_by_status("CHECKED_IN"),

            "checked_out":
                self.repo.count_by_status("CHECKED_OUT"),

        }

    def pending_visitors(self):

        return self.repo.get_pending()

    def visitors_inside(self):

        return self.repo.get_inside()