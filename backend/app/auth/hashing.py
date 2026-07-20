from pwdlib import PasswordHash

password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    """
    Hash a plain-text password.
    """
    return password_hash.hash(password)


def verify_password(
    password: str,
    password_hash_value: str,
) -> bool:
    """
    Verify a plain-text password against its hash.
    """
    return password_hash.verify(
        password,
        password_hash_value,
    )