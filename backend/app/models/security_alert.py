from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class SecurityAlert(Base):

    __tablename__ = "security_alerts"

    id: Mapped[int] = mapped_column(primary_key=True)

    resident_id: Mapped[int | None] = mapped_column(
        ForeignKey("residents.id"),
        nullable=True,
    )

    title: Mapped[str] = mapped_column(
        String(100),
    )

    message: Mapped[str] = mapped_column(
        String(500),
    )

    alert_type: Mapped[str] = mapped_column(
        String(50),
    )

    severity: Mapped[str] = mapped_column(
        String(20),
        default="MEDIUM",
    )

    is_resolved: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )

    resident = relationship("Resident")