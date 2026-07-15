from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.user_repository import UserRepository

from app.schemas.user import UserRegister
from app.schemas.user import UserResponse

from app.services.auth_service import AuthService
from app.schemas.token import LoginRequest, Token

from app.auth.dependencies import get_current_user
from app.models.user import User
from fastapi.security import OAuth2PasswordRequestForm


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


@router.post(
    "/register",
    response_model=UserResponse
)
def register(
    user: UserRegister,
    db: Session = Depends(get_db)
):

    repo = UserRepository(db)

    service = AuthService(repo)

    return service.register(user)

@router.post(
    "/login",
    response_model=Token,
)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    repo = UserRepository(db)
    service = AuthService(repo)

    return service.login(
        email=form_data.username,
        password=form_data.password,
    )

@router.get(
    "/me",
    response_model=UserResponse,
)
def get_me(
    current_user: User = Depends(get_current_user),
):

    return current_user