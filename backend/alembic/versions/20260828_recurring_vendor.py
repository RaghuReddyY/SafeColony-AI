"""add recurring order vendor routing

Revision ID: 20260828_recurring_vendor
Revises: 20260828_notification_navigation
"""
from alembic import op
import sqlalchemy as sa

revision = "20260828_recurring_vendor"
down_revision = "20260828_notification_navigation"
branch_labels = None
depends_on = None

def upgrade():
    op.add_column("recurring_orders", sa.Column("vendor_id", sa.Integer(), nullable=True))
    op.create_index("ix_recurring_orders_vendor_id", "recurring_orders", ["vendor_id"])
    op.create_foreign_key("fk_recurring_orders_vendor_id", "recurring_orders", "marketplace_vendors", ["vendor_id"], ["id"], ondelete="SET NULL")

def downgrade():
    op.drop_constraint("fk_recurring_orders_vendor_id", "recurring_orders", type_="foreignkey")
    op.drop_index("ix_recurring_orders_vendor_id", table_name="recurring_orders")
    op.drop_column("recurring_orders", "vendor_id")
