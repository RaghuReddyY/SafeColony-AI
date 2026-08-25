"""separate owner/tenant family invites and maintenance payer

Revision ID: 20260824_owner_tenant_household
Revises: 20260824_email_verification
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260824_owner_tenant_household"
down_revision: Union[str, Sequence[str], None] = "20260824_email_verification"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "units",
        sa.Column("tenant_family_join_code", sa.String(length=24), nullable=True),
    )
    op.create_index(
        "ix_units_tenant_family_join_code",
        "units",
        ["tenant_family_join_code"],
        unique=True,
    )

    op.add_column(
        "units",
        sa.Column("maintenance_payer_resident_id", sa.Integer(), nullable=True),
    )
    op.create_index(
        "ix_units_maintenance_payer_resident_id",
        "units",
        ["maintenance_payer_resident_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_units_maintenance_payer_resident_id",
        "units",
        "residents",
        ["maintenance_payer_resident_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column(
        "residents",
        sa.Column("family_sponsor_resident_id", sa.Integer(), nullable=True),
    )
    op.create_index(
        "ix_residents_family_sponsor_resident_id",
        "residents",
        ["family_sponsor_resident_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_residents_family_sponsor_resident_id",
        "residents",
        "residents",
        ["family_sponsor_resident_id"],
        ["id"],
        ondelete="SET NULL",
    )

    # Preserve the current application's maintenance behaviour. Existing
    # primary residents remain the payer for their unit after deployment.
    op.execute(sa.text("""
        UPDATE units u
        SET maintenance_payer_resident_id = r.id
        FROM residents r
        WHERE r.unit_id = u.id
          AND r.is_primary = TRUE
    """))


def downgrade() -> None:
    op.drop_constraint(
        "fk_residents_family_sponsor_resident_id",
        "residents",
        type_="foreignkey",
    )
    op.drop_index(
        "ix_residents_family_sponsor_resident_id",
        table_name="residents",
    )
    op.drop_column("residents", "family_sponsor_resident_id")

    op.drop_constraint(
        "fk_units_maintenance_payer_resident_id",
        "units",
        type_="foreignkey",
    )
    op.drop_index(
        "ix_units_maintenance_payer_resident_id",
        table_name="units",
    )
    op.drop_column("units", "maintenance_payer_resident_id")

    op.drop_index(
        "ix_units_tenant_family_join_code",
        table_name="units",
    )
    op.drop_column("units", "tenant_family_join_code")
