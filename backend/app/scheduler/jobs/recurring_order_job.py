from app.core.logger import logger
from app.database.session import SessionLocal
from app.services.super_app_service import SuperAppService
from app.scheduler.base_job import BaseJob

class RecurringOrderJob(BaseJob):
    def name(self) -> str:
        return "Recurring Order Generation Job"

    def interval_minutes(self) -> int:
        return 60

    def run(self) -> None:
        db = SessionLocal()
        try:
            generated = SuperAppService(db).process_recurring_orders()
            if generated:
                logger.info("Generated %s recurring marketplace order(s).", generated)
        except Exception:
            logger.exception("Recurring order generation job failed.")
        finally:
            db.close()
