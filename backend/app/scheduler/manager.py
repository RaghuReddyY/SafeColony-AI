from apscheduler.schedulers.background import BackgroundScheduler

from app.scheduler.registry import JobRegistry


class SchedulerManager:
    """
    Manages the lifecycle of the APScheduler instance.
    It starts all registered jobs and gracefully shuts down.
    """

    def __init__(self, registry: JobRegistry):
        self.registry = registry
        self.scheduler = BackgroundScheduler()

    def start(self):
        """
        Register all jobs with APScheduler and start it.
        """
        for job in self.registry.get_jobs():

            self.scheduler.add_job(
                func=job.run,
                trigger="interval",
                minutes=job.interval_minutes(),
                id=job.name(),
                replace_existing=True,
            )

            print(
                f"[Scheduler] Registered Job : "
                f"{job.name()} "
                f"(Every {job.interval_minutes()} minutes)"
            )

        self.scheduler.start()
        print("[Scheduler] Started Successfully.")

    def shutdown(self):
        """
        Shutdown APScheduler.
        """
        if self.scheduler.running:
            self.scheduler.shutdown()
            print("[Scheduler] Shutdown Completed.")