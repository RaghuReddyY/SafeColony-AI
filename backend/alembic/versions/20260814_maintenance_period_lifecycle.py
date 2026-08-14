"""add maintenance period lifecycle

Revision ID: 20260814_mlife
Revises: 20260814_cf_rules
"""
from alembic import op
import sqlalchemy as sa

revision = "20260814_mlife"
down_revision = "20260814_cf_rules"
branch_labels = None
depends_on = None

def upgrade():
    op.add_column("maintenance_periods", sa.Column("status", sa.String(20), nullable=False, server_default="DRAFT"))
    op.create_index("ix_maintenance_periods_status", "maintenance_periods", ["status"])
    op.execute("UPDATE maintenance_periods SET status = 'PUBLISHED' WHERE id IN (SELECT DISTINCT period_id FROM maintenance_bills)")

def downgrade():
    op.drop_index("ix_maintenance_periods_status", table_name="maintenance_periods")
    op.drop_column("maintenance_periods", "status")
