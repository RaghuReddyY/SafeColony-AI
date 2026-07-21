from datetime import date

from sqlalchemy.orm import Session

from app.enums.vacation_status import VacationStatus
from app.models.vacation_mode import VacationMode


class VacationRepository:

    def __init__(self, db: Session):
        self.db = db

    # =====================================================
    # Create
    # =====================================================

    def create(self, vacation: VacationMode) -> VacationMode:
        self.db.add(vacation)
        self.db.commit()
        self.db.refresh(vacation)
        return vacation

    # =====================================================
    # Save
    # =====================================================

    def save(self, vacation: VacationMode) -> VacationMode:
        self.db.commit()
        self.db.refresh(vacation)
        return vacation

    # =====================================================
    # Get By ID
    # =====================================================

    def get_by_id(self, vacation_id: int) -> VacationMode | None:

        return (
            self.db.query(VacationMode)
            .filter(VacationMode.id == vacation_id)
            .first()
        )

    # =====================================================
    # Resident History
    # =====================================================

    def get_by_resident(
        self,
        resident_id: int,
    ) -> list[VacationMode]:

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id
            )
            .order_by(
                VacationMode.created_at.desc()
            )
            .all()
        )

    # =====================================================
    # Active Vacation
    # =====================================================

    def get_active(
        self,
        resident_id: int,
    ) -> VacationMode | None:

        today = date.today()

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == VacationStatus.ACTIVE.value,
                VacationMode.start_date <= today,
                VacationMode.end_date >= today,
            )
            .first()
        )

    # =====================================================
    # Scheduled Vacation
    # =====================================================

    def get_scheduled(
        self,
        resident_id: int,
    ) -> list[VacationMode]:

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == VacationStatus.SCHEDULED.value,
            )
            .all()
        )

    # =====================================================
    # Is Resident On Vacation
    # =====================================================

    def is_resident_on_vacation(
        self,
        resident_id: int,
    ) -> VacationMode | None:

        return self.get_active(resident_id)

    # =====================================================
    # Active Vacations
    # =====================================================

    def get_active_vacations(self) -> list[VacationMode]:

        today = date.today()

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.status == VacationStatus.ACTIVE.value,
                VacationMode.start_date <= today,
                VacationMode.end_date >= today,
            )
            .order_by(
                VacationMode.end_date.asc()
            )
            .all()
        )

    # =====================================================
    # Overlapping Vacation
    # =====================================================

    def has_overlapping_vacation(
        self,
        resident_id: int,
        start_date,
        end_date,
    ) -> VacationMode | None:

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status.in_(
                    [
                        VacationStatus.ACTIVE.value,
                        VacationStatus.SCHEDULED.value,
                    ]
                ),
                VacationMode.start_date <= end_date,
                VacationMode.end_date >= start_date,
            )
            .first()
        )

    # =====================================================
    # Resident Summary
    # =====================================================

    def get_summary(self, resident_id: int):

        return {
            "total_active": (
                self.db.query(VacationMode)
                .filter(
                    VacationMode.resident_id == resident_id,
                    VacationMode.status == VacationStatus.ACTIVE.value,
                )
                .count()
            ),
            "total_scheduled": (
                self.db.query(VacationMode)
                .filter(
                    VacationMode.resident_id == resident_id,
                    VacationMode.status == VacationStatus.SCHEDULED.value,
                )
                .count()
            ),
            "total_completed": (
                self.db.query(VacationMode)
                .filter(
                    VacationMode.resident_id == resident_id,
                    VacationMode.status == VacationStatus.COMPLETED.value,
                )
                .count()
            ),
            "total_cancelled": (
                self.db.query(VacationMode)
                .filter(
                    VacationMode.resident_id == resident_id,
                    VacationMode.status == VacationStatus.CANCELLED.value,
                )
                .count()
            ),
        }

    # =====================================================
    # Scheduler
    # =====================================================

    def get_scheduled_to_activate(self) -> list[VacationMode]:

        today = date.today()

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.status == VacationStatus.SCHEDULED.value,
                VacationMode.start_date <= today,
            )
            .all()
        )

    # =====================================================
    # Complete Active Vacations
    # =====================================================

    def get_active_to_complete(self) -> list[VacationMode]:

        today = date.today()

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.status == VacationStatus.ACTIVE.value,
                VacationMode.end_date < today,
            )
            .all()
        )