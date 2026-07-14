from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class Delivery(Base):

    __tablename__ = "deliveries"

    id: Mapped[int] = mapped_column(primary_key=True)

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
    )

    courier_name: Mapped[str] = mapped_column(
        String(100),
    )

    tracking_number: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    package_type: Mapped[str] = mapped_column(
        String(50),
    )

    status: Mapped[str] = mapped_column(
        String(30),
        default="ARRIVED",
    )

    received_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    delivered_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )

    resident = relationship(
        "Resident",
    )