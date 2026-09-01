from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from app.config import settings


def _normalize_database_url(url: str) -> str:
    """
    Normalize the DATABASE_URL to use the correct async driver.
    - postgres:// or postgresql:// → postgresql+psycopg://  (Neon / Render / Supabase)
    - sqlite:// → sqlite+aiosqlite://  (local development fallback)
    - Already correct URLs are returned unchanged.
    """
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    elif url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    elif url.startswith("sqlite:///") and not url.startswith("sqlite+aiosqlite:///"):
        return url.replace("sqlite:///", "sqlite+aiosqlite:///", 1)
    return url


db_url = _normalize_database_url(settings.DATABASE_URL)

# SQLite requires connect_args for async compatibility
connect_args = {"check_same_thread": False} if "sqlite" in db_url else {}

engine = create_async_engine(
    db_url,
    echo=False,
    pool_pre_ping=True,
    connect_args=connect_args,
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    expire_on_commit=False,
    class_=AsyncSession,
)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
