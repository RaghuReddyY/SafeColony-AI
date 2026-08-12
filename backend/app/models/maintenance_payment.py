from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class MaintenancePayment(Base):
    __tablename__ = "maintenance_payments"

    id: Mapped[int] = mapped_column(primary_key=True)
    bill_id: Mapped[int] = mapped_column(
        ForeignKey("maintenance_bills.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    amount: Mapped[Decimal] = mapped_column(
        Numeric(12, 2),
        nullable=False,
    )
    payment_method: Mapped[str] = mapped_column(
        String(30),
        default="MANUAL",
        nullable=False,
    )
    reference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        default="VERIFIED",
        nullable=False,
        server_default="VERIFIED",
    )
    paid_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )
    verified_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
    )
    recorded_by: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
    )

    bill = relationship(
        "MaintenanceBill",
        back_populates="payments",
    )
