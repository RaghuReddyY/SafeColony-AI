"""add block scoped maintenance periods"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "d4e5f6a7b8c9"
down_revision: Union[str, Sequence[str], None] = "c3d4e5f6a7b8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("maintenance_periods", sa.Column("section_id", sa.Integer(), nullable=True))
    op.create_index("ix_maintenance_periods_section_id", "maintenance_periods", ["section_id"])
    op.create_foreign_key("fk_maintenance_periods_section_id", "maintenance_periods", "sections", ["section_id"], ["id"], ondelete="SET NULL")
    op.drop_constraint("uq_maintenance_period_org_month", "maintenance_periods", type_="unique")
    op.create_index(
        "uq_maintenance_org_community_month",
        "maintenance_periods",
        ["organization_id", "month"],
        unique=True,
        postgresql_where=sa.text("section_id IS NULL"),
    )
    op.create_index(
        "uq_maintenance_org_block_month",
        "maintenance_periods",
        ["organization_id", "section_id", "month"],
        unique=True,
        postgresql_where=sa.text("section_id IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("uq_maintenance_org_block_month", table_name="maintenance_periods")
    op.drop_index("uq_maintenance_org_community_month", table_name="maintenance_periods")
    op.create_unique_constraint("uq_maintenance_period_org_month", "maintenance_periods", ["organization_id", "month"])
    op.drop_constraint("fk_maintenance_periods_section_id", "maintenance_periods", type_="foreignkey")
    op.drop_index("ix_maintenance_periods_section_id", table_name="maintenance_periods")
    op.drop_column("maintenance_periods", "section_id")
