from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt

from app.config import settings


def create_access_token(data: dict):

    now = datetime.now(timezone.utc)

    payload = data.copy()

    payload.update(
        {
            "iat": now,
            "exp": now + timedelta(
                minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
            ),
            "type": "access",
        }
    )

    return jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


def decode_access_token(token: str):

    try:
        return jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )

    except JWTError:
        return None