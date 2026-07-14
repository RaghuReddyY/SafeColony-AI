from datetime import date

from fastapi import HTTPException

from app.core.event_bus import event_bus
from app.events.vacation_events import (
    VacationStartedEvent,
    VacationCancelledEvent,
)
from app.models.vacation_mode import VacationMode


class VacationService:

    def __init__(self, vacation_repo):

        self.vacation_repo = vacation_repo

    def enable(self, data):

        if data.end_date < data.start_date:

            raise HTTPException(
                status_code=400,
                detail="End date must be after start date",
            )

        existing = self.vacation_repo.get_active(
            data.resident_id
        )

        if existing:

            raise HTTPException(
                status_code=400,
                detail="Vacation Mode already active",
            )

        vacation = VacationMode(
            resident_id=data.resident_id,
            start_date=data.start_date,
            end_date=data.end_date,
            reason=data.reason,
            emergency_contact=data.emergency_contact,
            allow_visitors=data.allow_visitors,
            allow_deliveries=data.allow_deliveries,
            notify_security=data.notify_security,
            monitoring_enabled=data.monitoring_enabled,
        )

        vacation = self.vacation_repo.create(vacation)

        resident = vacation.resident

        event = VacationStartedEvent(
            resident_id=resident.id,
            resident_name=resident.full_name,
            start_date=vacation.start_date,
            end_date=vacation.end_date,
            allow_visitors=vacation.allow_visitors,
            allow_deliveries=vacation.allow_deliveries,
        )

        event_bus.publish(event)

        return vacation

    def get_history(
        self,
        resident_id: int,
    ):

        return self.vacation_repo.get_by_resident(
            resident_id
        )

    def cancel(
        self,
        vacation_id: int,
    ):

        vacation = (
            self.vacation_repo.db.query(VacationMode)
            .filter(
                VacationMode.id == vacation_id
            )
            .first()
        )

        if vacation is None:

            raise HTTPException(
                status_code=404,
                detail="Vacation not found",
            )

        vacation.status = "CANCELLED"

        vacation = self.vacation_repo.save(
            vacation
        )

        resident = vacation.resident

        event = VacationCancelledEvent(
            resident_id=resident.id,
            resident_name=resident.full_name,
        )

        event_bus.publish(event)

        return vacation

    def get_active_vacations(self):

        vacations = (
            self.vacation_repo.get_active_vacations()
        )

        today = date.today()

        response = []

        for vacation in vacations:

            response.append(
                {
                    "resident_name":
                        vacation.resident.full_name,

                    "unit_number":
                        vacation.resident.unit.unit_number,

                    "start_date":
                        vacation.start_date,

                    "end_date":
                        vacation.end_date,

                    "days_remaining":
                        (
                            vacation.end_date
                            - today
                        ).days,
                }
            )

        return response