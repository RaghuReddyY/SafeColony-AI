from sqlalchemy.orm import Session

from app.models.organization_application import OrganizationApplication
from app.enums import OrganizationApplicationStatus


class OrganizationApplicationRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        application: OrganizationApplication,
    ) -> OrganizationApplication:

        self.db.add(application)
        self.db.commit()
        self.db.refresh(application)

        return application

    def get_by_id(
        self,
        application_id: int,
    ) -> OrganizationApplication | None:

        return (
            self.db.query(OrganizationApplication)
            .filter(
                OrganizationApplication.id == application_id
            )
            .first()
        )

    def get_by_email(
        self,
        email: str,
    ) -> OrganizationApplication | None:

        return (
            self.db.query(OrganizationApplication)
            .filter(
                OrganizationApplication.email == email
            )
            .first()
        )

    def get_pending(self):

        return (
            self.db.query(OrganizationApplication)
            .filter(
                OrganizationApplication.status
                == OrganizationApplicationStatus.PENDING.value
            )
            .order_by(
                OrganizationApplication.created_at.desc()
            )
            .all()
        )

    def update(
        self,
        application: OrganizationApplication,
    ) -> OrganizationApplication:

        self.db.commit()
        self.db.refresh(application)

        return application