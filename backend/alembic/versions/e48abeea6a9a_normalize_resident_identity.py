"""Normalize resident identity

Revision ID: e48abeea6a9a
Revises: 28cdbe26e564
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "e48abeea6a9a"
down_revision: Union[str, Sequence[str], None] = "28cdbe26e564"
branch_labels = None
depends_on = None


def upgrade():

    bind = op.get_bind()

    # ------------------------------------------------------------------
    # Create PostgreSQL Enums
    # ------------------------------------------------------------------

    resident_status = postgresql.ENUM(
        "PENDING",
        "ACTIVE",
        "REJECTED",
        "SUSPENDED",
        name="residentstatus",
    )

    resident_status.create(bind, checkfirst=True)

    resident_type = postgresql.ENUM(
        "OWNER",
        "TENANT",
        "FAMILY",
        name="residenttype",
    )

    resident_type.create(bind, checkfirst=True)

    # ------------------------------------------------------------------
    # user_id
    # ------------------------------------------------------------------

    op.add_column(
        "residents",
        sa.Column(
            "user_id",
            sa.Integer(),
            nullable=True,
        ),
    )

    # ------------------------------------------------------------------
    # status
    # ------------------------------------------------------------------

    op.add_column(
        "residents",
        sa.Column(
            "status",
            resident_status,
            nullable=False,
            server_default="PENDING",
        ),
    )

    # ------------------------------------------------------------------

    op.alter_column(
        "residents",
        "unit_id",
        existing_type=sa.Integer(),
        nullable=True,
    )

    op.alter_column(
        "residents",
        "resident_type",
        existing_type=sa.String(length=20),
        type_=resident_type,
        existing_nullable=False,
        postgresql_using="resident_type::residenttype",
    )

    # ------------------------------------------------------------------

    op.drop_index("ix_resident_phone", table_name="residents")
    op.drop_index("ix_resident_email", table_name="residents")

    op.drop_constraint(
        "residents_phone_key",
        "residents",
        type_="unique",
    )

    op.drop_constraint(
        "residents_email_key",
        "residents",
        type_="unique",
    )

    op.drop_column("residents", "phone")
    op.drop_column("residents", "email")
    op.drop_column("residents", "full_name")

    op.create_index(
        "ix_resident_status",
        "residents",
        ["status"],
    )

    op.create_index(
        "ix_residents_user_id",
        "residents",
        ["user_id"],
        unique=True,
    )

    op.create_foreign_key(
        "fk_resident_user",
        "residents",
        "users",
        ["user_id"],
        ["id"],
    )

    op.alter_column(
        "vacation_modes",
        "updated_at",
        nullable=False,
        existing_type=postgresql.TIMESTAMP(),
    )


def downgrade():

    bind = op.get_bind()

    op.alter_column(
        "vacation_modes",
        "updated_at",
        nullable=True,
        existing_type=postgresql.TIMESTAMP(),
    )

    op.drop_constraint(
        "fk_resident_user",
        "residents",
        type_="foreignkey",
    )

    op.drop_index(
        "ix_residents_user_id",
        table_name="residents",
    )

    op.drop_index(
        "ix_resident_status",
        table_name="residents",
    )

    op.add_column(
        "residents",
        sa.Column("full_name", sa.String(100), nullable=False),
    )

    op.add_column(
        "residents",
        sa.Column("email", sa.String(120), nullable=True),
    )

    op.add_column(
        "residents",
        sa.Column("phone", sa.String(20), nullable=False),
    )

    op.create_unique_constraint(
        "residents_phone_key",
        "residents",
        ["phone"],
    )

    op.create_unique_constraint(
        "residents_email_key",
        "residents",
        ["email"],
    )

    op.create_index(
        "ix_resident_phone",
        "residents",
        ["phone"],
    )

    op.create_index(
        "ix_resident_email",
        "residents",
        ["email"],
    )

    op.drop_column("residents", "status")
    op.drop_column("residents", "user_id")

    resident_status = postgresql.ENUM(
        "PENDING",
        "ACTIVE",
        "REJECTED",
        "SUSPENDED",
        name="residentstatus",
    )

    resident_status.drop(bind, checkfirst=True)

    resident_type = postgresql.ENUM(
        "OWNER",
        "TENANT",
        "FAMILY",
        name="residenttype",
    )

    resident_type.drop(bind, checkfirst=True)