from apscheduler.schedulers.background import BackgroundScheduler

from app.scheduler.registry import JobRegistry
from app.core.logger import logger

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
                max_instances=1,
                coalesce=True,
                misfire_grace_time=60,
            )

            logger.info(
                    "Registered scheduler job '%s' (every %d minutes).",
                    job.name(),
                    job.interval_minutes(),
                )

        try:
            self.scheduler.start()
            logger.info("Scheduler started successfully.")
        except Exception:
            logger.exception("Unable to start scheduler.")
            raise
        

    def shutdown(self):
        """
        Shutdown APScheduler.
        """
        if not self.scheduler.running:
            return

        try:
            self.scheduler.shutdown(wait=False)
            logger.info("Scheduler shutdown completed.")
        except Exception:
            logger.exception("Scheduler shutdown failed.")
           