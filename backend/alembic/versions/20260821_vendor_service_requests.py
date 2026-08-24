"""add vendor linkage to service requests
Revision ID: 20260821_vendor_service_requests
Revises: 276da8935bc7
"""
from alembic import op
import sqlalchemy as sa
revision="20260821_vendor_service_requests"
down_revision="276da8935bc7"
branch_labels=None
depends_on=None
def upgrade():
    op.add_column("service_requests", sa.Column("vendor_id", sa.Integer(), nullable=True))
    op.create_index("ix_service_requests_vendor_id", "service_requests", ["vendor_id"])
    op.create_foreign_key("fk_service_requests_vendor_id", "service_requests", "marketplace_vendors", ["vendor_id"], ["id"], ondelete="SET NULL")
def downgrade():
    op.drop_constraint("fk_service_requests_vendor_id", "service_requests", type_="foreignkey")
    op.drop_index("ix_service_requests_vendor_id", table_name="service_requests")
    op.drop_column("service_requests", "vendor_id")
