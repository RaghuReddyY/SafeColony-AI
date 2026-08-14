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

        # ------------------------------------------------------------------
    # Guard Management
    # ------------------------------------------------------------------

    def create_guard(
        self,
        current_user,
        data,
    ):

        if self.user_repo.exists_by_email(data.email):
            raise ConflictException(
                "Email already exists."
            )

        if self.user_repo.exists_by_phone(data.phone):
            raise ConflictException(
                "Phone already exists."
            )

        guard = User(
            full_name=data.full_name,
            email=data.email.lower().strip(),
            phone=data.phone.strip(),
            password_hash=hash_password(data.password),
            role=UserRole.SECURITY_GUARD.value,
            status=UserStatus.ACTIVE.value,
            organization_id=current_user.organization_id,
            is_active=True,
        )

        return self.user_repo.create_guard(guard)

    # ------------------------------------------------------------------

    def get_guards(
        self,
        current_user,
    ):

        return self.user_repo.get_guards_by_organization(
            current_user.organization_id,
        )

    # ------------------------------------------------------------------
    # Guard Management
    # ------------------------------------------------------------------

    def create_guard(
        self,
        current_user,
        data,
    ):

        if self.user_repo.exists_by_email(data.email):
            raise ConflictException(
                "Email already exists."
            )

        if self.user_repo.exists_by_phone(data.phone):
            raise ConflictException(
                "Phone already exists."
            )

        guard = User(
            full_name=data.full_name,
            email=data.email.lower().strip(),
            phone=data.phone.strip(),
            password_hash=hash_password(data.password),
            role=UserRole.SECURITY_GUARD.value,
            status=UserStatus.ACTIVE.value,
            organization_id=current_user.organization_id,
            is_active=True,
        )

        return self.user_repo.create_guard(guard)

    # ------------------------------------------------------------------

    def get_guards(
        self,
        current_user,
    ):

        return self.user_repo.get_guards_by_organization(
            current_user.organization_id,
        )
    
    def _default_property_type(
        self,
        organization_type: str,
    ) -> PropertyType:

        if organization_type == "APARTMENT":
            return PropertyType.APARTMENT

        # Residential layouts are treated as gated communities
        return PropertyType.GATED_COMMUNITY
# ------------------------------------------------------------------
# Scoped administration helpers
# ------------------------------------------------------------------

def _create_scoped_admin(self, current_user, data, role: UserRole):
    from app.models.user_block_scope import UserBlockScope

    if current_user.role not in {UserRole.SYSTEM_ADMIN.value, UserRole.ORGANIZATION_ADMIN.value}:
        raise ConflictException("Only the community administrator can create scoped administrators.")

    if self.user_repo.exists_by_email(data.email.lower().strip()):
        raise ConflictException("Email already exists.")
    if self.user_repo.exists_by_phone(data.phone.strip()):
        raise ConflictException("Phone already exists.")

    section_ids = list(dict.fromkeys(data.section_ids)) if hasattr(data, "section_ids") else []
    if role == UserRole.BLOCK_ADMIN and not section_ids:
        raise ConflictException("At least one block is required for a block administrator.")

    if section_ids:
        sections = (
            self.db.query(Section)
            .join(Property, Section.property_id == Property.id)
            .filter(
                Section.id.in_(section_ids),
                Property.organization_id == current_user.organization_id,
            )
            .all()
        )
        if len(sections) != len(section_ids):
            raise ConflictException("One or more selected blocks do not belong to this community.")
    else:
        sections = []

    user = User(
        full_name=data.full_name.strip(),
        email=data.email.lower().strip(),
        phone=data.phone.strip(),
        password_hash=hash_password(data.password),
        role=role.value,
        status=UserStatus.ACTIVE.value,
        organization_id=current_user.organization_id,
        is_active=True,
    )
    self.db.add(user)
    self.db.flush()

    for section in sections:
        self.db.add(UserBlockScope(user_id=user.id, section_id=section.id))

    self.db.commit()
    self.db.refresh(user)
    return user


def create_block_admin(self, current_user, data):
    return _create_scoped_admin(self, current_user, data, UserRole.BLOCK_ADMIN)


def create_finance_admin(self, current_user, data):
    return _create_scoped_admin(self, current_user, data, UserRole.COMMUNITY_FINANCE_ADMIN)


def get_scoped_admins(self, current_user):
    from app.models.user_block_scope import UserBlockScope
    users = (
        self.db.query(User)
        .filter(
            User.organization_id == current_user.organization_id,
            User.role.in_([UserRole.BLOCK_ADMIN.value, UserRole.COMMUNITY_FINANCE_ADMIN.value]),
            User.is_active.is_(True),
        )
        .order_by(User.full_name.asc())
        .all()
    )
    result = []
    for user in users:
        scopes = (
            self.db.query(UserBlockScope, Section)
            .join(Section, UserBlockScope.section_id == Section.id)
            .filter(UserBlockScope.user_id == user.id)
            .all()
        )
        result.append({
            "id": user.id,
            "full_name": user.full_name,
            "email": user.email,
            "phone": user.phone,
            "role": user.role,
            "section_ids": [scope.section_id for scope, _ in scopes],
            "section_names": [section.name for _, section in scopes],
        })
    return result

OrganizationService._create_scoped_admin = _create_scoped_admin
OrganizationService.create_block_admin = create_block_admin
OrganizationService.create_finance_admin = create_finance_admin
OrganizationService.get_scoped_admins = get_scoped_admins
