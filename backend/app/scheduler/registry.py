class JobRegistry:

    def __init__(self):
        self._jobs = []

    def register(self, job):
        self._jobs.append(job)

    def get_jobs(self):
        return self._jobs