"""enhance community marketplace lifecycle and service booking

Revision ID: marketplace_20260821_enhancements
Revises: marketplace_20260821
"""
from alembic import op
import sqlalchemy as sa

revision = "marketplace_20260821_enhancements"
down_revision = "marketplace_20260821"
branch_labels = None
depends_on = None

def upgrade():
    op.add_column("marketplace_orders", sa.Column("service_slot", sa.String(80), nullable=True))
    op.add_column("marketplace_orders", sa.Column("payment_reference", sa.String(120), nullable=True))

def downgrade():
    op.drop_column("marketplace_orders", "payment_reference")
    op.drop_column("marketplace_orders", "service_slot")
