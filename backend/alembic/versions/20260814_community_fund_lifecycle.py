"""add community fund lifecycle

Revision ID: 20260814_cflife
Revises: 20260814_mlife
"""
from alembic import op
import sqlalchemy as sa

revision = "20260814_cflife"
down_revision = "20260814_mlife"
branch_labels = None
depends_on = None

def upgrade():
    op.execute("UPDATE community_funds SET status = 'PUBLISHED' WHERE status = 'OPEN'")

def downgrade():
    op.execute("UPDATE community_funds SET status = 'OPEN' WHERE status = 'PUBLISHED'")
