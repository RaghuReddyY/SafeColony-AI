from app.core.logger import logger
from app.database.session import SessionLocal
from app.repositories.maintenance_repository import MaintenanceRepository
from app.services.maintenance_service import MaintenanceService
from app.scheduler.base_job import BaseJob


class MaintenanceJob(BaseJob):
    def name(self) -> str:
        return "Maintenance Reminder Job"

    def interval_minutes(self) -> int:
        return 60

    def run(self) -> None:
        db = SessionLocal()
        try:
            MaintenanceService(MaintenanceRepository(db)).send_daily_due_reminders()
        except Exception:
            logger.exception("Maintenance reminder job failed.")
        finally:
            db.close()
