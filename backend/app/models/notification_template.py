from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class NotificationTemplate(Base):
    """Reusable notification template for supported delivery channels."""

    __tablename__ = "notification_templates"
    __table_args__ = (
        UniqueConstraint("organization_id", "code", name="uq_notification_template_org_code"),
        Index("ix_notification_template_org_active", "organization_id", "is_active"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    organization_id: Mapped[int] = mapped_column(
        ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    code: Mapped[str] = mapped_column(String(80), nullable=False)
    title_template: Mapped[str] = mapped_column(String(200), nullable=False)
    message_template: Mapped[str] = mapped_column(Text, nullable=False)
    channel: Mapped[str] = mapped_column(String(20), default="IN_APP", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )


class NotificationDelivery(Base):
    """Delivery attempt/outbox record for push, email, SMS or WhatsApp."""

    __tablename__ = "notification_deliveries"
    __table_args__ = (
        Index("ix_notification_delivery_status", "status"),
        Index("ix_notification_delivery_notification", "notification_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    notification_id: Mapped[int] = mapped_column(
        ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False
    )
    channel: Mapped[str] = mapped_column(String(20), nullable=False)
    destination: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="PENDING", nullable=False)
    attempts: Mapped[int] = mapped_column(default=0, nullable=False)
    provider_message_id: Mapped[str | None] = mapped_column(String(200), nullable=True)
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    notification = relationship("Notification", back_populates="deliveries")
