from sqlalchemy.orm import Session

from app.core.exceptions import ConflictException
from app.auth.hashing import hash_password
from app.enums import UserRole, UserStatus
from app.models.organization import Organization
from app.models.user import User
from app.repositories.organization_repository import OrganizationRepository
from app.repositories.user_repository import UserRepository


class OrganizationService:

    def __init__(self, db: Session):
        self.db = db
        self.organization_repo = OrganizationRepository(db)
        self.user_repo = UserRepository(db)

    # ------------------------------------------------------------------
    # Existing CRUD
    # ------------------------------------------------------------------

    def create(self, data):

        if self.organization_repo.get_by_name(data.name):
            raise ConflictException("Organization already exists")

        if self.organization_repo.get_by_email(data.email):
            raise ConflictException("Organization email already exists")

        organization = Organization(
            name=data.name,
            organization_type=data.organization_type,
            email=data.email,
            phone=data.phone,
            address=data.address,
            city=data.city,
            state=data.state,
            country=data.country,
            pincode=data.pincode,
        )

        return self.organization_repo.create(organization)

    def get_all(self):
        return self.organization_repo.get_all()

    # ------------------------------------------------------------------
    # Organization Onboarding
    # ------------------------------------------------------------------

    def onboard(self, request):

        if self.organization_repo.get_by_name(request.organization.name):
            raise ConflictException("Organization already exists")

        if self.organization_repo.get_by_email(request.organization.email):
            raise ConflictException("Organization email already exists")

        if self.user_repo.exists_by_email(request.admin.email):
            raise ConflictException("Admin email already exists")

        if self.user_repo.exists_by_phone(request.admin.phone):
            raise ConflictException("Admin phone already exists")

        try:

            # ----------------------------------------------------------
            # Create Organization
            # ----------------------------------------------------------

            organization = Organization(
                name=request.organization.name,
                organization_type=request.organization.organization_type,
                email=request.organization.email,
                phone=request.organization.phone,
                address=request.organization.address,
                city=request.organization.city,
                state=request.organization.state,
                country=request.organization.country,
                pincode=request.organization.pincode,
            )

            self.organization_repo.create(
                organization,
                commit=False,
            )

            # ----------------------------------------------------------
            # Create Organization Admin
            # ----------------------------------------------------------

            admin = User(
                full_name=request.admin.full_name,
                email=request.admin.email,
                phone=request.admin.phone,
                password_hash=hash_password(request.admin.password),
                role=UserRole.ORGANIZATION_ADMIN.value,
                status=UserStatus.ACTIVE.value,
                organization_id=organization.id,
                is_active=True,
            )

            self.user_repo.create(
                admin,
                create_resident=False,
                commit=False,
            )

            self.db.commit()

            self.db.refresh(organization)
            self.db.refresh(admin)

            return {
                "message": "Organization onboarded successfully",
                "organization_id": organization.id,
                "organization_name": organization.name,
                "admin_user_id": admin.id,
                "admin_email": admin.email,
            }

        except Exception:
            self.db.rollback()
            raise