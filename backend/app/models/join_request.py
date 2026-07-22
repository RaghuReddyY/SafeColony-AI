from datetime import datetime

from sqlalchemy import (
    Integer,
    ForeignKey,
    Enum,
    DateTime,
)

from sqlalchemy.orm import (
    Mapped,
    mapped_column,
    relationship,
)

from app.database.base_class import Base
from app.enums import JoinStatus


class JoinRequest(Base):

    __tablename__ = "join_requests"


    id: Mapped[int] = mapped_column(
        primary_key=True
    )


    user_id: Mapped[int] = mapped_column(
        ForeignKey(
            "users.id",
            ondelete="CASCADE"
        ),
        nullable=False,
    )


    organization_id: Mapped[int] = mapped_column(
        ForeignKey(
            "organizations.id",
            ondelete="CASCADE"
        ),
        nullable=False,
    )


    requested_unit_id: Mapped[int | None] = mapped_column(
        ForeignKey(
            "units.id"
        ),
        nullable=True,
    )


    assigned_unit_id: Mapped[int | None] = mapped_column(
        ForeignKey(
            "units.id"
        ),
        nullable=True,
    )


    status: Mapped[JoinStatus] = mapped_column(
        Enum(JoinStatus),
        default=JoinStatus.PENDING,
        nullable=False,
    )


    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )


    user = relationship(
        "User"
    )


    organization = relationship(
        "Organization"
    )


    assigned_unit = relationship(
        "Unit",
        foreign_keys=[assigned_unit_id],
    )