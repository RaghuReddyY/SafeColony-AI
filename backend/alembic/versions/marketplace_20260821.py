"""add community marketplace

Revision ID: marketplace_20260821
Revises: 20260814_maintenance_period_lifecycle
Create Date: 2026-08-21
"""
from alembic import op
import sqlalchemy as sa

revision = "marketplace_20260821"
down_revision = "3a1b2c4d5e6f"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "marketplace_vendors",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True, unique=True),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("category", sa.String(60), nullable=False),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_marketplace_vendors_organization_id", "marketplace_vendors", ["organization_id"])
    op.create_index("ix_marketplace_vendors_category", "marketplace_vendors", ["category"])

    op.create_table(
        "marketplace_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("vendor_id", sa.Integer(), sa.ForeignKey("marketplace_vendors.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_by_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(160), nullable=False),
        sa.Column("category", sa.String(60), nullable=False),
        sa.Column("event_type", sa.String(20), nullable=False, server_default="PRODUCT"),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("cutoff_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("scheduled_for", sa.DateTime(timezone=True), nullable=True),
        sa.Column("delivery_mode", sa.String(30), nullable=False, server_default="COMMUNITY_DROP"),
        sa.Column("status", sa.String(20), nullable=False, server_default="OPEN"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_marketplace_events_organization_id", "marketplace_events", ["organization_id"])
    op.create_index("ix_marketplace_events_category", "marketplace_events", ["category"])

    op.create_table(
        "marketplace_orders",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("event_id", sa.Integer(), sa.ForeignKey("marketplace_events.id", ondelete="CASCADE"), nullable=False),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("resident_user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="PLACED"),
        sa.Column("payment_status", sa.String(20), nullable=False, server_default="PENDING"),
        sa.Column("delivery_mode", sa.String(30), nullable=False, server_default="COMMUNITY_DROP"),
        sa.Column("total_amount", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_marketplace_orders_event_id", "marketplace_orders", ["event_id"])
    op.create_index("ix_marketplace_orders_organization_id", "marketplace_orders", ["organization_id"])
    op.create_index("ix_marketplace_orders_resident_user_id", "marketplace_orders", ["resident_user_id"])

    op.create_table(
        "marketplace_order_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("order_id", sa.Integer(), sa.ForeignKey("marketplace_orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("unit", sa.String(30), nullable=False, server_default="unit"),
        sa.Column("unit_price", sa.Numeric(12, 2), nullable=False, server_default="0"),
    )
    op.create_index("ix_marketplace_order_items_order_id", "marketplace_order_items", ["order_id"])


def downgrade():
    op.drop_table("marketplace_order_items")
    op.drop_table("marketplace_orders")
    op.drop_table("marketplace_events")
    op.drop_table("marketplace_vendors")
