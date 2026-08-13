"""add chat message edit/delete fields

Revision ID: 9c1a7e5b4d22
Revises: 8b4f9c7d2e11
Create Date: 2026-08-13
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "9c1a7e5b4d22"
down_revision: Union[str, Sequence[str], None] = "8b4f9c7d2e11"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("chat_messages", sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("chat_messages", sa.Column("deleted_at", sa.DateTime(), nullable=True))
    op.alter_column("chat_messages", "is_deleted", server_default=None)


def downgrade() -> None:
    op.drop_column("chat_messages", "deleted_at")
    op.drop_column("chat_messages", "is_deleted")
