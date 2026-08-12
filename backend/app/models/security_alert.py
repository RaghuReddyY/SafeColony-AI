from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class SecurityAlert(Base):
    """Security and emergency alert raised inside an organization."""

    __tablename__ = "security_alerts"

    __table_args__ = (
        Index("ix_security_alert_org_created", "organization_id", "created_at"),
        Index("ix_security_alert_org_resolved", "organization_id", "is_resolved"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    organization_id: Mapped[int | None] = mapped_column(
        ForeignKey("organizations.id"),
        nullable=True,
        index=True,
    )

    resident_id: Mapped[int | None] = mapped_column(
        ForeignKey("residents.id"),
        nullable=True,
        index=True,
    )

    raised_by_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
        index=True,
    )

    title: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    message: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )

    alert_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    severity: Mapped[str] = mapped_column(
        String(20),
        default="MEDIUM",
        nullable=False,
    )

    source_role: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True,
    )

    is_resolved: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    resolved_by_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
    )

    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    resident = relationship("Resident")

    raised_by = relationship(
        "User",
        foreign_keys=[raised_by_user_id],
    )

    resolved_by = relationship(
        "User",
        foreign_keys=[resolved_by_user_id],
    )

    @property
    def raised_by_name(self) -> str | None:
        return self.raised_by.full_name if self.raised_by else None

    @property
    def resolved_by_name(self) -> str | None:
        return self.resolved_by.full_name if self.resolved_by else None

    @property
    def unit_number(self) -> str | None:
        return self.resident.unit_number if self.resident else None
