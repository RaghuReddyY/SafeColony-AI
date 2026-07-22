"""add user status

Revision ID: 910ed72a2973
Revises: c0fef441ae6f
Create Date: 2026-07-22 12:02:59.727557

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "910ed72a2973"
down_revision: Union[str, Sequence[str], None] = "c0fef441ae6f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add the status column with a temporary server default
    op.add_column(
        "users",
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default="ACTIVE",
        ),
    )

    # Create index
    op.create_index(
        "ix_users_status",
        "users",
        ["status"],
        unique=False,
    )

    # Remove the server default so SQLAlchemy controls future defaults
    op.alter_column(
        "users",
        "status",
        server_default=None,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_users_status",
        table_name="users",
    )

    op.drop_column(
        "users",
        "status",
    )