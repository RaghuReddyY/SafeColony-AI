"""complete pending modules: incidents, complaints, amenities, notification outbox and maintenance policy

Revision ID: 7f3c2a9d4b11
Revises: c4b7e5f1d2a9
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "7f3c2a9d4b11"
down_revision: Union[str, Sequence[str], None] = "c4b7e5f1d2a9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Notification audit/outbox
    op.add_column("notifications", sa.Column("updated_at", sa.DateTime(), nullable=True))
    op.execute("UPDATE notifications SET updated_at = created_at WHERE updated_at IS NULL")
    op.alter_column("notifications", "updated_at", nullable=False)

    op.create_table(
        "notification_templates",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("code", sa.String(80), nullable=False),
        sa.Column("title_template", sa.String(200), nullable=False),
        sa.Column("message_template", sa.Text(), nullable=False),
        sa.Column("channel", sa.String(20), nullable=False, server_default="IN_APP"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("organization_id", "code", name="uq_notification_template_org_code"),
    )
    op.create_index("ix_notification_template_org_active", "notification_templates", ["organization_id", "is_active"])

    op.create_table(
        "notification_deliveries",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("notification_id", sa.Integer(), sa.ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False),
        sa.Column("channel", sa.String(20), nullable=False),
        sa.Column("destination", sa.String(255), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="PENDING"),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("provider_message_id", sa.String(200), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("sent_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_notification_delivery_status", "notification_deliveries", ["status"])
    op.create_index("ix_notification_delivery_notification", "notification_deliveries", ["notification_id"])

    op.create_table(
        "notification_devices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token", sa.String(500), nullable=False),
        sa.Column("platform", sa.String(20), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "token", name="uq_notification_device_user_token"),
    )
    op.create_index("ix_notification_device_user_active", "notification_devices", ["user_id", "is_active"])

    # Maintenance late fee policy
    op.add_column("organizations", sa.Column("late_fee_type", sa.String(20), nullable=True, server_default="NONE"))
    op.add_column("organizations", sa.Column("late_fee_value", sa.Numeric(12, 2), nullable=True, server_default="0"))
    op.add_column("organizations", sa.Column("late_fee_grace_days", sa.Integer(), nullable=True, server_default="0"))
    op.execute("UPDATE organizations SET late_fee_type='NONE' WHERE late_fee_type IS NULL")
    op.execute("UPDATE organizations SET late_fee_value=0 WHERE late_fee_value IS NULL")
    op.execute("UPDATE organizations SET late_fee_grace_days=0 WHERE late_fee_grace_days IS NULL")
    op.alter_column("organizations", "late_fee_type", nullable=False)
    op.alter_column("organizations", "late_fee_value", nullable=False)
    op.alter_column("organizations", "late_fee_grace_days", nullable=False)

    op.add_column("security_alerts", sa.Column("updated_at", sa.DateTime(), nullable=True))
    op.execute("UPDATE security_alerts SET updated_at = created_at WHERE updated_at IS NULL")
    op.alter_column("security_alerts", "updated_at", nullable=False)

    # Incident management
    op.create_table(
        "incidents",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(150), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("incident_type", sa.String(50), nullable=False),
        sa.Column("severity", sa.String(20), nullable=False, server_default="MEDIUM"),
        sa.Column("status", sa.String(30), nullable=False, server_default="OPEN"),
        sa.Column("location", sa.String(200), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("assigned_to_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("investigation_notes", sa.Text(), nullable=True),
        sa.Column("resolution_notes", sa.Text(), nullable=True),
        sa.Column("resolved_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_incident_org_status", "incidents", ["organization_id", "status"])
    op.create_index("ix_incident_org_created", "incidents", ["organization_id", "created_at"])

    op.create_table(
        "incident_evidence",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("incident_id", sa.Integer(), sa.ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("evidence_type", sa.String(30), nullable=False),
        sa.Column("file_url", sa.String(500), nullable=True),
        sa.Column("description", sa.String(500), nullable=True),
        sa.Column("uploaded_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_incident_evidence_incident", "incident_evidence", ["incident_id"])

    # Complaints
    op.create_table(
        "complaints",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("resident_id", sa.Integer(), sa.ForeignKey("residents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(150), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("category", sa.String(60), nullable=False),
        sa.Column("priority", sa.String(20), nullable=False, server_default="MEDIUM"),
        sa.Column("status", sa.String(30), nullable=False, server_default="OPEN"),
        sa.Column("assigned_to_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("escalated_at", sa.DateTime(), nullable=True),
        sa.Column("escalation_reason", sa.String(500), nullable=True),
        sa.Column("resolution", sa.Text(), nullable=True),
        sa.Column("resolved_at", sa.DateTime(), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_complaint_org_status", "complaints", ["organization_id", "status"])
    op.create_index("ix_complaint_org_created", "complaints", ["organization_id", "created_at"])
    op.create_index("ix_complaint_resident", "complaints", ["resident_id"])

    # Amenities
    op.create_table(
        "amenities",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("amenity_type", sa.String(50), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", sa.String(200), nullable=True),
        sa.Column("capacity", sa.Integer(), nullable=True),
        sa.Column("booking_required", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("approval_required", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("opening_time", sa.String(10), nullable=True),
        sa.Column("closing_time", sa.String(10), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_amenity_org_active", "amenities", ["organization_id", "is_active"])

    op.create_table(
        "amenity_bookings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("amenity_id", sa.Integer(), sa.ForeignKey("amenities.id", ondelete="CASCADE"), nullable=False),
        sa.Column("resident_id", sa.Integer(), sa.ForeignKey("residents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("start_at", sa.DateTime(), nullable=False),
        sa.Column("end_at", sa.DateTime(), nullable=False),
        sa.Column("purpose", sa.String(300), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="PENDING"),
        sa.Column("approved_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("approved_at", sa.DateTime(), nullable=True),
        sa.Column("rejection_reason", sa.String(500), nullable=True),
        sa.Column("cancelled_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_amenity_booking_amenity_time", "amenity_bookings", ["amenity_id", "start_at", "end_at"])
    op.create_index("ix_amenity_booking_resident", "amenity_bookings", ["resident_id"])
    op.create_index("ix_amenity_booking_status", "amenity_bookings", ["status"])


def downgrade() -> None:
    op.drop_index("ix_amenity_booking_status", table_name="amenity_bookings")
    op.drop_index("ix_amenity_booking_resident", table_name="amenity_bookings")
    op.drop_index("ix_amenity_booking_amenity_time", table_name="amenity_bookings")
    op.drop_table("amenity_bookings")
    op.drop_index("ix_amenity_org_active", table_name="amenities")
    op.drop_table("amenities")

    op.drop_index("ix_complaint_resident", table_name="complaints")
    op.drop_index("ix_complaint_org_created", table_name="complaints")
    op.drop_index("ix_complaint_org_status", table_name="complaints")
    op.drop_table("complaints")

    op.drop_index("ix_incident_evidence_incident", table_name="incident_evidence")
    op.drop_table("incident_evidence")
    op.drop_index("ix_incident_org_created", table_name="incidents")
    op.drop_index("ix_incident_org_status", table_name="incidents")
    op.drop_table("incidents")

    op.drop_column("security_alerts", "updated_at")
    op.drop_column("organizations", "late_fee_grace_days")
    op.drop_column("organizations", "late_fee_value")
    op.drop_column("organizations", "late_fee_type")

    op.drop_index("ix_notification_device_user_active", table_name="notification_devices")
    op.drop_table("notification_devices")

    op.drop_index("ix_notification_delivery_notification", table_name="notification_deliveries")
    op.drop_index("ix_notification_delivery_status", table_name="notification_deliveries")
    op.drop_table("notification_deliveries")
    op.drop_index("ix_notification_template_org_active", table_name="notification_templates")
    op.drop_table("notification_templates")
    op.drop_column("notifications", "updated_at")
