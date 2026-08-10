"""change_notifications_to_user

Revision ID: f5f29adfe386
Revises: 4af4ba7b7d61
Create Date: 2026-08-04 13:44:31.096564

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "f5f29adfe386"
down_revision: Union[str, Sequence[str], None] = "4af4ba7b7d61"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:

    # Rename resident_id -> user_id
    op.alter_column(
        "notifications",
        "resident_id",
        new_column_name="user_id",
        existing_type=sa.Integer(),
    )

    # Drop existing foreign key
    op.drop_constraint(
        "notifications_resident_id_fkey",
        "notifications",
        type_="foreignkey",
    )

    # Create new foreign key
    op.create_foreign_key(
        "notifications_user_id_fkey",
        "notifications",
        "users",
        ["user_id"],
        ["id"],
    )


def downgrade() -> None:

    op.drop_constraint(
        "notifications_user_id_fkey",
        "notifications",
        type_="foreignkey",
    )

    op.alter_column(
        "notifications",
        "user_id",
        new_column_name="resident_id",
        existing_type=sa.Integer(),
    )

    op.create_foreign_key(
        "notifications_resident_id_fkey",
        "notifications",
        "residents",
        ["resident_id"],
        ["id"],
    )