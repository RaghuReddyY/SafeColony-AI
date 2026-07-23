import secrets

from sqlalchemy.orm import Session

from app.auth.hashing import hash_password
from app.core.exceptions import ConflictException
from app.enums import UserRole, UserStatus
from app.models.organization import Organization
from app.models.user import User
from app.repositories.organization_repository import OrganizationRepository
from app.repositories.user_repository import UserRepository
from app.models.property import Property
from app.models.section import Section

from app.repositories.property_repository import PropertyRepository
from app.repositories.section_repository import SectionRepository

from app.enums import PropertyType

class OrganizationService:

    def __init__(self, db: Session):
        self.db = db

        self.organization_repo = OrganizationRepository(db)
        self.user_repo = UserRepository(db)

        self.property_repo = PropertyRepository(db)
        self.section_repo = SectionRepository(db)
    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _generate_organization_code(self) -> str:

        while True:

            code = f"SC-{secrets.token_hex(3).upper()}"

            if not self.organization_repo.get_by_code(code):
                return code

    # ------------------------------------------------------------------
    # Organization Creation
    # ------------------------------------------------------------------

    def create_organization(
        self,
        *,
        name: str,
        organization_type: str,
        email: str,
        phone: str,
        address: str | None = None,
        city: str | None = None,
        state: str | None = None,
        country: str | None = None,
        pincode: str | None = None,
        commit: bool = False,
    ) -> Organization:

        if self.organization_repo.get_by_name(name):
            raise ConflictException("Organization already exists")

        if self.organization_repo.get_by_email(email):
            raise ConflictException("Organization email already exists")
        
        if self.organization_repo.get_by_phone(phone):
            raise ConflictException("Organization phone already exists")

        organization = Organization(
            name=name,
            organization_code=self._generate_organization_code(),
            organization_type=organization_type,
            email=email,
            phone=phone,
            address=address,
            city=city,
            state=state,
            country=country,
            pincode=pincode,
            is_active=True,
        )

        return self.organization_repo.create(
            organization,
            commit=commit,
        )

    # ------------------------------------------------------------------
    # Organization Admin Creation
    # ------------------------------------------------------------------

    def create_organization_admin(
        self,
        *,
        organization_id: int,
        full_name: str,
        email: str,
        phone: str,
        password: str,
        commit: bool = False,
    ) -> User:

        if self.user_repo.exists_by_email(email):
            raise ConflictException("Admin email already exists")

        if self.user_repo.exists_by_phone(phone):
            raise ConflictException("Admin phone already exists")

        admin = User(
            full_name=full_name,
            email=email,
            phone=phone,
            password_hash=hash_password(password),
            role=UserRole.ORGANIZATION_ADMIN.value,
            status=UserStatus.ACTIVE.value,
            organization_id=organization_id,
            is_active=True,
        )

        return self.user_repo.create(
            admin,
            commit=commit,
        )

    # ------------------------------------------------------------------
    # Existing CRUD
    # ------------------------------------------------------------------

    def create(self, data):

        return self.create_organization(
            name=data.name,
            organization_type=data.organization_type,
            email=data.email,
            phone=data.phone,
            address=data.address,
            city=data.city,
            state=data.state,
            country=data.country,
            pincode=data.pincode,
            commit=True,
        )

    def get_all(self):

        return self.organization_repo.get_all()

    # ------------------------------------------------------------------
    # Complete Onboarding
    # ------------------------------------------------------------------

    def onboard(self, request):

        try:

            # ----------------------------------------------------
            # Create Organization
            # ----------------------------------------------------

            organization = self.create_organization(
                name=request.organization.name,
                organization_type=request.organization.organization_type,
                email=request.organization.email,
                phone=request.organization.phone,
                address=request.organization.address,
                city=request.organization.city,
                state=request.organization.state,
                country=request.organization.country,
                pincode=request.organization.pincode,
                commit=False,
            )

            # ----------------------------------------
            # Create Default Property
            # ----------------------------------------

            default_property = Property(
                name=organization.name,
                property_type=self._default_property_type(
                    organization.organization_type,
                ),
                organization_id=organization.id,

                address=organization.address,
                city=organization.city,
                state=organization.state,
                country=organization.country,
                pincode=organization.pincode,
            )

            default_property = self.property_repo.create(
                default_property,
                commit=False,
            )

            # ----------------------------------------
            # Create Default Section
            # ----------------------------------------

            default_section = Section(
                property_id=default_property.id,
                name="Main",
                description="Default Section",
            )

            self.section_repo.create(
                default_section,
                commit=False,
            )
            # ----------------------------------------------------
            # Create Organization Admin
            # ----------------------------------------------------

            admin = self.create_organization_admin(
                organization_id=organization.id,
                full_name=request.admin.full_name,
                email=request.admin.email,
                phone=request.admin.phone,
                password=request.admin.password,
                commit=False,
            )

            self.db.commit()

            self.db.refresh(organization)
            self.db.refresh(default_property)
            self.db.refresh(default_section)
            self.db.refresh(admin)

            return {
                "message": "Organization onboarded successfully",
                "organization_id": organization.id,
                "organization_code": organization.organization_code,
                "organization_name": organization.name,
                "property_id": default_property.id,
                "section_id": default_section.id,
                "admin_user_id": admin.id,
                "admin_email": admin.email,
            }

        except Exception:
            self.db.rollback()
            raise

    def _default_property_type(
        self,
        organization_type: str,
    ) -> PropertyType:

        if organization_type == "APARTMENT":
            return PropertyType.APARTMENT

        # Residential layouts are treated as gated communities
        return PropertyType.GATED_COMMUNITY