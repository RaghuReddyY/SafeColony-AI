from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base_class import Base


class Permission(Base):
    """
    Represents an application permission.

    Examples:
        resident:create
        resident:view
        visitor:approve
    """

    __tablename__ = "permissions"

    id: Mapped[int] = mapped_column(
        primary_key=True,
    )

    code: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        index=True,
        nullable=False,
    )

    module: Mapped[str] = mapped_column(
        String(50),
        index=True,
        nullable=False,
    )

    description: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )