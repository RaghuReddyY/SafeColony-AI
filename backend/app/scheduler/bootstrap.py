from app.scheduler.jobs.vacation_job import VacationJob
from app.scheduler.manager import SchedulerManager
from app.scheduler.registry import JobRegistry


def create_scheduler() -> SchedulerManager:
    registry = JobRegistry()

    registry.register(VacationJob())

    return SchedulerManager(registry)