class JobRegistry:

    def __init__(self):
        self._jobs = []

    def register(self, job):
        if any(existing.name() == job.name() for existing in self._jobs):
            raise ValueError(
                f"Job '{job.name()}' already registered."
            )

        self._jobs.append(job)

    def get_jobs(self):
        return self._jobs