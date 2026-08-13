"""add explicit chat message edited flag

Revision ID: a17e6c9f3b21
Revises: 9c1a7e5b4d22
Create Date: 2026-08-13
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a17e6c9f3b21"
down_revision: Union[str, Sequence[str], None] = "9c1a7e5b4d22"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "chat_messages",
        sa.Column("is_edited", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.alter_column("chat_messages", "is_edited", server_default=None)


def downgrade() -> None:
    op.drop_column("chat_messages", "is_edited")
