from app.scheduler.jobs.vacation_job import VacationJob
from app.scheduler.jobs.maintenance_job import MaintenanceJob
from app.scheduler.jobs.notification_job import NotificationJob
from app.scheduler.jobs.recurring_order_job import RecurringOrderJob
from app.scheduler.manager import SchedulerManager
from app.scheduler.registry import JobRegistry


def create_scheduler() -> SchedulerManager:
    registry = JobRegistry()

    registry.register(VacationJob())
    registry.register(MaintenanceJob())
    registry.register(NotificationJob())
    registry.register(RecurringOrderJob())

    return SchedulerManager(registry)