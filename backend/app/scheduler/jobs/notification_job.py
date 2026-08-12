from app.core.logger import logger
from app.database.session import SessionLocal
from app.repositories.notification_repository import NotificationRepository
from app.services.notification_service import NotificationService
from app.scheduler.base_job import BaseJob


class NotificationJob(BaseJob):
    def name(self) -> str:
        return "Notification Outbox Job"

    def interval_minutes(self) -> int:
        return 5

    def run(self) -> None:
        db = SessionLocal()
        try:
            NotificationService(NotificationRepository(db)).process_pending_deliveries()
        except Exception:
            logger.exception("Notification outbox job failed.")
        finally:
            db.close()
