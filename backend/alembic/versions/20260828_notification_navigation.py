"""add notification navigation metadata

Revision ID: 20260828_notification_navigation
Revises: 20260824_owner_tenant_household
"""
from alembic import op
import sqlalchemy as sa

revision = "20260828_notification_navigation"
down_revision = "20260824_owner_tenant_household"
branch_labels = None
depends_on = None

def upgrade():
    op.add_column("notifications", sa.Column("entity_type", sa.String(length=40), nullable=True))
    op.add_column("notifications", sa.Column("entity_id", sa.Integer(), nullable=True))
    op.add_column("notifications", sa.Column("action", sa.String(length=80), nullable=True))
    op.create_index("ix_notifications_entity_type", "notifications", ["entity_type"])
    op.create_index("ix_notifications_entity_id", "notifications", ["entity_id"])

def downgrade():
    op.drop_index("ix_notifications_entity_id", table_name="notifications")
    op.drop_index("ix_notifications_entity_type", table_name="notifications")
    op.drop_column("notifications", "action")
    op.drop_column("notifications", "entity_id")
    op.drop_column("notifications", "entity_type")
