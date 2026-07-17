from fastapi import Depends, HTTPException, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.auth.jwt_handler import decode_access_token
from app.database.session import get_db
from app.repositories.user_repository import UserRepository

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    # Debug logs
    print("Authorization Header:", request.headers.get("Authorization"))
    print("Token:", token)

    # Decode JWT
    payload = decode_access_token(token)

    print("Payload:", payload)

    if payload is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid token",
        )

    email = payload.get("sub")

    if email is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid token payload",
        )

    repo = UserRepository(db)

    user = repo.get_by_email(email)

    print("User from DB:", user)

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="User not found",
        )

    return user