from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.token import Token
from app.schemas.otp import OTPRequest, OTPRequestResponse, OTPVerifyRequest
from app.schemas.user import (
    ChangePasswordRequest,
    RegisterResponse,
    UserRegister,
    UserResponse,
)
from app.services.auth_service import AuthService

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


def get_auth_service(
        db: Session = Depends(get_db),
    ) -> AuthService:
        return AuthService(db)

@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register User",
)
def register(
    user: UserRegister,
    service: AuthService = Depends(get_auth_service),
):
    return service.register(user)


@router.post(
    "/login",
    response_model=Token,
    summary="User Login",
)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    service: AuthService = Depends(get_auth_service),
):
    return service.login(
        email=form_data.username,
        password=form_data.password,
    )


@router.post(
    "/otp/request",
    response_model=OTPRequestResponse,
    summary="Request mobile login OTP",
)
def request_otp(
    data: OTPRequest,
    service: AuthService = Depends(get_auth_service),
):
    return service.request_otp(data.phone)


@router.post(
    "/otp/verify",
    response_model=Token,
    summary="Verify mobile login OTP",
)
def verify_otp(
    data: OTPVerifyRequest,
    service: AuthService = Depends(get_auth_service),
):
    return service.verify_otp(data.phone, data.otp)


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Current Logged-in User",
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    organization = current_user.organization
    return {
        "id": current_user.id,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "phone": current_user.phone,
        "role": current_user.role,
        "is_active": current_user.is_active,
        "organization_id": current_user.organization_id,
        "organization_code": organization.organization_code if organization else None,
        "organization_name": organization.name if organization else None,
    }


@router.post(
    "/change-password",
    status_code=status.HTTP_200_OK,
    summary="Change Password",
)
def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    service: AuthService = Depends(get_auth_service),
):
    service.change_password(
        user=current_user,
        current_password=request.current_password,
        new_password=request.new_password,
    )

    return {
        "message": "Password changed successfully."
    }