import os
from pydantic_settings import BaseSettings
from typing import Optional, List


class Settings(BaseSettings):
    APP_ENV: str = "production"  # development | production
    ENABLE_API_DOCS: bool = False  # Disable /docs in production by default

    # Database — set DATABASE_URL env var in Render Dashboard
    # Falls back to local SQLite for safe local development
    DATABASE_URL: str = "sqlite+aiosqlite:///./sembukutty_kovil_local.db"

    # JWT Security Settings
    JWT_SECRET_KEY: str = "3f8a91b2c4e5d6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS — allow all origins so Flutter mobile app (Android/iOS/Chrome) can reach Render Cloud API
    CORS_ORIGINS: str = "*"
    CLOUDFLARE_TUNNEL_NAME: str = "temple-billing-tunnel"

    # Default Admin Credentials
    ADMIN_USERNAME: str = "admin"
    ADMIN_PASSWORD: str = "kovil2024"

    # SMTP Email Credentials
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = "sembukuttysastha.kovil@gmail.com"
    SMTP_PASSWORD: str = "dgajdotfifhtbrrg"
    SMTP_FROM_EMAIL: str = "sembukuttysastha.kovil@gmail.com"

    # SMS Gateway
    FAST2SMS_API_KEY: str = ""

    @property
    def allowed_origins_list(self) -> List[str]:
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
