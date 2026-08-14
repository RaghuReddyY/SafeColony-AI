"""add block admin scopes and finance role support"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "b2d3e4f5a6c7"
down_revision: Union[str, Sequence[str], None] = "a17e6c9f3b21"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "user_block_scopes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("section_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["section_id"], ["sections.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id", "section_id", name="uq_user_block_scope"),
    )
    op.create_index("ix_user_block_scopes_user_id", "user_block_scopes", ["user_id"])
    op.create_index("ix_user_block_scopes_section_id", "user_block_scopes", ["section_id"])


def downgrade() -> None:
    op.drop_index("ix_user_block_scopes_section_id", table_name="user_block_scopes")
    op.drop_index("ix_user_block_scopes_user_id", table_name="user_block_scopes")
    op.drop_table("user_block_scopes")
