from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.database import engine, Base
import app.models  # Ensures all ORM models are registered with Base

from app.middleware.security_headers import SecurityHeadersMiddleware, production_exception_handler
from app.routers import (
    auth,
    staff,
    members,
    opening_balances,
    transactions,
    dashboard,
    reports,
    documents,
    backup,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Automatically create database tables on startup if they don't exist yet
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    except Exception as e:
        print(f"[!] Warning: Table creation on startup exception: {e}")
    yield


limiter = Limiter(key_func=get_remote_address)

# Disable /docs and /redoc in production if ENABLE_API_DOCS is False
docs_url = "/docs" if settings.ENABLE_API_DOCS else None
redoc_url = "/redoc" if settings.ENABLE_API_DOCS else None

app = FastAPI(
    title="Sembukutty Sastha Kovil — Billing & Accounts API",
    version="1.0.0",
    docs_url=docs_url,
    redoc_url=redoc_url,
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add Security Headers Middleware
app.add_middleware(SecurityHeadersMiddleware)

# Strict CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

# Exception sanitizer for 500 errors in production
if settings.APP_ENV == "production":
    app.add_exception_handler(Exception, production_exception_handler)

# Include API Routers
app.include_router(auth)
app.include_router(staff)
app.include_router(members)
app.include_router(opening_balances)
app.include_router(transactions)
app.include_router(dashboard)
app.include_router(reports)
app.include_router(documents)
app.include_router(backup)


@app.get("/")
async def root():
    return {"message": "Sembukutty Sastha Kovil — Billing & Accounts API", "version": "1.0.0"}


@app.get("/health")
async def health():
    """
    Production Health Check Endpoint:
    Returns basic status information without exposing internal metrics or paths.
    """
    return {"status": "healthy"}
