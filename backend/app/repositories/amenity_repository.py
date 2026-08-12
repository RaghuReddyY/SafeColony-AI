from sqlalchemy.orm import Session

from app.models.amenity import Amenity, AmenityBooking


class AmenityRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_amenities(self, organization_id):
        return (
            self.db.query(Amenity)
            .filter(Amenity.organization_id == organization_id)
            .order_by(Amenity.name.asc())
            .all()
        )

    def get_amenity(self, organization_id, amenity_id):
        return (
            self.db.query(Amenity)
            .filter(Amenity.organization_id == organization_id, Amenity.id == amenity_id)
            .first()
        )

    def create_amenity(self, amenity):
        self.db.add(amenity)
        self.db.flush()
        return amenity

    def save_amenity(self, amenity):
        self.db.add(amenity)
        self.db.flush()
        return amenity

    def create_booking(self, booking):
        self.db.add(booking)
        self.db.flush()
        return booking

    def get_booking(self, organization_id, booking_id):
        return (
            self.db.query(AmenityBooking)
            .join(AmenityBooking.amenity)
            .filter(
                AmenityBooking.id == booking_id,
                Amenity.organization_id == organization_id,
            )
            .first()
        )

    def overlapping(self, amenity_id, start_at, end_at, exclude_booking_id=None):
        q = (
            self.db.query(AmenityBooking)
            .filter(
                AmenityBooking.amenity_id == amenity_id,
                AmenityBooking.status.in_(["PENDING", "APPROVED"]),
                AmenityBooking.start_at < end_at,
                AmenityBooking.end_at > start_at,
            )
        )
        if exclude_booking_id is not None:
            q = q.filter(AmenityBooking.id != exclude_booking_id)
        return q.first()

    def list_bookings(self, organization_id, resident_id=None, status=None):
        q = (
            self.db.query(AmenityBooking)
            .join(AmenityBooking.amenity)
            .filter(Amenity.organization_id == organization_id)
        )
        if resident_id is not None:
            q = q.filter(AmenityBooking.resident_id == resident_id)
        if status:
            q = q.filter(AmenityBooking.status == status)
        return q.order_by(AmenityBooking.start_at.desc()).all()

    def commit(self):
        self.db.commit()
