from datetime import date, datetime

from app.core.event_bus import event_bus
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.enums.vacation_status import VacationStatus
from app.events.vacation_events import (
    VacationCancelledEvent,
    VacationStartedEvent,
)
from app.models.vacation_mode import VacationMode


class VacationService:

    def __init__(self, vacation_repo):
        self.vacation_repo = vacation_repo

    # =====================================================
    # Enable Vacation Mode
    # =====================================================

    def enable(self, data):

        today = datetime.utcnow().date()

        if data.end_date < data.start_date:
            raise BadRequestException(
                "End date must be greater than or equal to start date."
            )

        overlapping = self.vacation_repo.has_overlapping_vacation(
            resident_id=data.resident_id,
            start_date=data.start_date,
            end_date=data.end_date,
        )

        if overlapping:
            raise ConflictException(
                "An active or scheduled vacation already exists for this period."
            )

        if data.start_date <= today:
            status = VacationStatus.ACTIVE
            activated_at = datetime.utcnow()
        else:
            status = VacationStatus.SCHEDULED
            activated_at = None

        vacation = VacationMode(
            resident_id=data.resident_id,
            start_date=data.start_date,
            end_date=data.end_date,
            reason=data.reason,
            emergency_contact=data.emergency_contact,
            visitor_policy=data.visitor_policy.value,
            delivery_policy=data.delivery_policy.value,
            notify_security=data.notify_security,
            monitoring_enabled=data.monitoring_enabled,
            status=status.value,
            activated_at=activated_at,
            updated_at=datetime.utcnow(),
        )

        vacation = self.vacation_repo.create(vacation)

        # Publish event only when vacation becomes ACTIVE
        if vacation.status == VacationStatus.ACTIVE.value:

            resident = vacation.resident

            event = VacationStartedEvent(
                resident_id=resident.id,
                resident_name=resident.full_name,
                start_date=vacation.start_date,
                end_date=vacation.end_date,
                visitor_policy=vacation.visitor_policy,
                delivery_policy=vacation.delivery_policy,
            )

            event_bus.publish(event)

        return vacation

    # =====================================================
    # Resident Vacation History
    # =====================================================

    def get_history(self, resident_id: int):

        return self.vacation_repo.get_by_resident(resident_id)

    # =====================================================
    # Cancel Vacation
    # =====================================================

    def cancel(self, vacation_id: int):

        vacation = self.vacation_repo.get_by_id(vacation_id)

        if vacation is None:
            raise NotFoundException("Vacation")

        if vacation.status == VacationStatus.CANCELLED.value:
            raise BadRequestException(
                "Vacation is already cancelled."
            )

        if vacation.status == VacationStatus.COMPLETED.value:
            raise BadRequestException(
                "Completed vacation cannot be cancelled."
            )

        vacation.status = VacationStatus.CANCELLED.value
        vacation.deactivated_at = datetime.utcnow()
        vacation.updated_at = datetime.utcnow()

        vacation = self.vacation_repo.save(vacation)

        resident = vacation.resident

        event = VacationCancelledEvent(
            resident_id=resident.id,
            resident_name=resident.full_name,
        )

        event_bus.publish(event)

        return vacation

    # =====================================================
    # Guard Dashboard
    # =====================================================

    def get_active_vacations(self):

        vacations = self.vacation_repo.get_active_vacations()

        today = datetime.utcnow().date()

        response = []

        for vacation in vacations:

            response.append(
                {
                    "resident_name": vacation.resident.full_name,
                    "unit_number": vacation.resident.unit.unit_number,
                    "start_date": vacation.start_date,
                    "end_date": vacation.end_date,
                    "visitor_policy": vacation.visitor_policy,
                    "delivery_policy": vacation.delivery_policy,
                    "emergency_contact": vacation.emergency_contact,
                    "days_remaining": (
                        vacation.end_date - today
                    ).days,
                }
            )

        return response

    # =====================================================
    # Vacation Summary
    # =====================================================

    def get_summary(self, resident_id: int):

        return self.vacation_repo.get_summary(resident_id)
    
        # =====================================================
    # Scheduler - Activate Scheduled Vacations
    # =====================================================

    def activate_scheduled_vacations(self):

        vacations = self.vacation_repo.get_scheduled_to_activate()

        for vacation in vacations:

            vacation.status = VacationStatus.ACTIVE.value
            vacation.activated_at = datetime.utcnow()
            vacation.updated_at = datetime.utcnow()

            self.vacation_repo.save(vacation)

            resident = vacation.resident

            event = VacationStartedEvent(
                resident_id=resident.id,
                resident_name=resident.full_name,
                start_date=vacation.start_date,
                end_date=vacation.end_date,
                visitor_policy=vacation.visitor_policy,
                delivery_policy=vacation.delivery_policy,
            )

            event_bus.publish(event)

        return len(vacations)

    # =====================================================
    # Scheduler - Complete Active Vacations
    # =====================================================

    def complete_expired_vacations(self):

        vacations = self.vacation_repo.get_active_to_complete()

        for vacation in vacations:

            vacation.status = VacationStatus.COMPLETED.value
            vacation.deactivated_at = datetime.utcnow()
            vacation.updated_at = datetime.utcnow()

            self.vacation_repo.save(vacation)

        return len(vacations)