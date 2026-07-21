from app.database.session import SessionLocal
from app.repositories.vacation_repository import VacationRepository
from app.services.vacation_service import VacationService
from app.scheduler.base_job import BaseJob
from app.core.logger import logger


class VacationJob(BaseJob):

    def name(self) -> str:
        return "Vacation Job"

    def interval_minutes(self) -> int:
        return 5

    def run(self) -> None:
        logger.info("Vacation Job started.")
        db = SessionLocal()

        try:
            repo = VacationRepository(db)
            service = VacationService(repo)

            activated = service.activate_scheduled_vacations()
            completed = service.complete_expired_vacations()

            logger.info(
                    f"Vacation Job completed. Activated={activated}, Completed={completed}"
            )
            
            print(
                f"[VacationJob] Activated={activated}, Completed={completed}"
            )

        except Exception:
            logger.exception("Vacation Job failed.")

        finally:
            db.close()