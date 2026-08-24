"""merge marketplace and super app migrations

Revision ID: 276da8935bc7
Revises: marketplace_20260821_enhancements, super_app_20260821
Create Date: 2026-08-21 11:24:34.356500

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '276da8935bc7'
down_revision: Union[str, Sequence[str], None] = ('marketplace_20260821_enhancements', 'super_app_20260821')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
