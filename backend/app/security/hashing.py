from passlib.context import CryptContext

# Configure Passlib with Argon2id as primary hasher, falling back to bcrypt for legacy compatibility
pwd_context = CryptContext(
    schemes=["argon2", "bcrypt"],
    deprecated="auto",
    argon2__memory_cost=65536,
    argon2__time_cost=3,
    argon2__parallelism=4,
)


def hash_secret(secret: str) -> str:
    """
    Hashes a password or PIN securely using Argon2id algorithm.
    """
    if not secret:
        return ""
    return pwd_context.hash(secret.strip())


def verify_secret(plain_secret: str, hashed_secret: str) -> bool:
    """
    Verifies a plain text password or PIN against an Argon2id/bcrypt hash.
    """
    if not plain_secret or not hashed_secret:
        return False
    try:
        return pwd_context.verify(plain_secret.strip(), hashed_secret)
    except Exception:
        return False
