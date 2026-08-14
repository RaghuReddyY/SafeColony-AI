"""add block scope to incidents"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, Sequence[str], None] = "b2d3e4f5a6c7"
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column("incidents", sa.Column("section_id", sa.Integer(), nullable=True))
    op.create_index("ix_incidents_section_id", "incidents", ["section_id"])
    op.create_foreign_key("fk_incidents_section_id", "incidents", "sections", ["section_id"], ["id"], ondelete="SET NULL")

def downgrade() -> None:
    op.drop_constraint("fk_incidents_section_id", "incidents", type_="foreignkey")
    op.drop_index("ix_incidents_section_id", table_name="incidents")
    op.drop_column("incidents", "section_id")
