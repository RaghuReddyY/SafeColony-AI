from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.token import Token
from app.schemas.user import (
    ChangePasswordRequest,
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
    repo = UserRepository(db)
    return AuthService(repo)


@router.post(
    "/register",
    response_model=UserResponse,
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


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Current Logged-in User",
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


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