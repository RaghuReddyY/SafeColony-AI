from datetime import datetime

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.core.logger import logger
from app.models.amenity import Amenity, AmenityBooking
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.user import User
from app.repositories.amenity_repository import AmenityRepository


class AmenityService:
    ADMIN_ROLES = {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER"}

    def __init__(self, repo: AmenityRepository):
        self.repo = repo
        self.db = repo.db

    def list_amenities(self, current_user):
        return self.repo.list_amenities(current_user.organization_id)

    def create_amenity(self, current_user, data):
        if current_user.role not in self.ADMIN_ROLES:
            raise ForbiddenException("Only administrators can manage amenities.")
        amenity = Amenity(
            organization_id=current_user.organization_id,
            name=data.name.strip(),
            amenity_type=data.amenity_type.strip().upper(),
            description=data.description,
            location=data.location,
            capacity=data.capacity,
            booking_required=data.booking_required,
            approval_required=data.approval_required,
            opening_time=data.opening_time,
            closing_time=data.closing_time,
        )
        self.repo.create_amenity(amenity)
        self.repo.commit()
        return amenity

    def update_amenity(self, current_user, amenity_id, data):
        if current_user.role not in self.ADMIN_ROLES:
            raise ForbiddenException("Only administrators can manage amenities.")
        amenity = self.repo.get_amenity(current_user.organization_id, amenity_id)
        if not amenity:
            raise NotFoundException("Amenity")
        for field in ("name", "amenity_type", "description", "location", "capacity", "booking_required",
                      "approval_required", "opening_time", "closing_time", "is_active"):
            setattr(amenity, field, getattr(data, field))
        self.repo.commit()
        return amenity

    def _resident(self, current_user):
        resident = self.db.query(Resident).filter(Resident.user_id == current_user.id).first()
        if not resident:
            raise NotFoundException("Resident")
        return resident

    def create_booking(self, current_user, data):
        resident = self._resident(current_user)
        amenity = self.repo.get_amenity(current_user.organization_id, data.amenity_id)
        if not amenity or not amenity.is_active:
            raise NotFoundException("Amenity")
        if data.end_at <= data.start_at:
            raise BadRequestException("Booking end time must be after start time.")
        if data.start_at < datetime.utcnow():
            raise BadRequestException("Booking cannot start in the past.")
        if amenity.booking_required is False:
            raise BadRequestException("This amenity does not require booking.")
        if self.repo.overlapping(amenity.id, data.start_at, data.end_at):
            raise BadRequestException("The amenity is already booked for the selected time.")
        status = "PENDING" if amenity.approval_required else "APPROVED"
        booking = AmenityBooking(
            amenity_id=amenity.id,
            resident_id=resident.id,
            created_by_user_id=current_user.id,
            start_at=data.start_at,
            end_at=data.end_at,
            purpose=data.purpose,
            status=status,
            approved_by_user_id=current_user.id if status == "APPROVED" else None,
            approved_at=datetime.utcnow() if status == "APPROVED" else None,
        )
        self.repo.create_booking(booking)
        self._notify_admins(
            current_user.organization_id,
            "Amenity Booking Request",
            f"{current_user.full_name} requested {amenity.name} from {data.start_at:%d-%m-%Y %H:%M}.",
        )
        self.repo.commit()
        logger.info("Amenity booking created id=%s amenity=%s resident=%s", booking.id, amenity.id, resident.id)
        return booking

    def _notify_admins(self, organization_id, title, message):
        users = self.db.query(User).filter(
            User.organization_id == organization_id,
            User.role.in_(["ORGANIZATION_ADMIN", "PROPERTY_MANAGER"]),
            User.is_active.is_(True),
        ).all()
        for user in users:
            self.db.add(Notification(
                user_id=user.id, title=title, message=message, notification_type="AMENITY"
            ))

    def list_bookings(self, current_user, status=None):
        resident_id = self._resident(current_user).id if current_user.role == "RESIDENT" else None
        return self.repo.list_bookings(current_user.organization_id, resident_id, status)

    def decide(self, current_user, booking_id, data):
        if current_user.role not in self.ADMIN_ROLES:
            raise ForbiddenException("Only administrators can approve amenity bookings.")
        booking = self.repo.get_booking(current_user.organization_id, booking_id)
        if not booking:
            raise NotFoundException("Amenity booking")
        if booking.status != "PENDING":
            raise BadRequestException("Only pending bookings can be approved or rejected.")
        if data.approve:
            if self.repo.overlapping(booking.amenity_id, booking.start_at, booking.end_at):
                raise BadRequestException("The selected time is no longer available.")
            booking.status = "APPROVED"
            booking.approved_by_user_id = current_user.id
            booking.approved_at = datetime.utcnow()
            message = f"Your booking for {booking.amenity.name} was approved."
        else:
            booking.status = "REJECTED"
            booking.rejection_reason = data.reason or "Booking rejected by administrator."
            message = f"Your booking for {booking.amenity.name} was rejected."
        self.db.add(Notification(
            user_id=booking.resident.user_id,
            title="Amenity Booking Updated",
            message=message,
            notification_type="AMENITY",
        ))
        self.repo.commit()
        return booking

    def cancel(self, current_user, booking_id):
        booking = self.repo.get_booking(current_user.organization_id, booking_id)
        if not booking:
            raise NotFoundException("Amenity booking")
        if current_user.role == "RESIDENT" and booking.resident.user_id != current_user.id:
            raise ForbiddenException("You can only cancel your own booking.")
        if booking.status not in {"PENDING", "APPROVED"}:
            raise BadRequestException("This booking cannot be cancelled.")
        booking.status = "CANCELLED"
        booking.cancelled_at = datetime.utcnow()
        self.repo.commit()
        return booking
