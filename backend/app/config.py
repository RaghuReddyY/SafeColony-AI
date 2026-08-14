from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Runtime environment. Keep DEVELOPMENT for local work and explicitly use
    # PRODUCTION on the deployed backend.
    APP_ENV: str = "DEVELOPMENT"

    DATABASE_URL: str
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    GEMINI_API_KEY: str | None = None
    GEMINI_MODEL: str = "gemini-2.5-flash"

    # Comma-separated values. Example:
    # CORS_ORIGINS=https://safecolony.com,https://www.safecolony.com
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8000,http://127.0.0.1:8000,http://localhost,http://127.0.0.1"

    # Comma-separated hostnames. In production set this to the backend domain,
    # e.g. ALLOWED_HOSTS=api.safecolony.com
    ALLOWED_HOSTS: str = "*"

    # Razorpay is optional. Communities without a gateway can use DIRECT_UPI.
    RAZORPAY_KEY_ID: str | None = None
    RAZORPAY_KEY_SECRET: str | None = None
    RAZORPAY_WEBHOOK_SECRET: str | None = None
    RAZORPAY_PAYMENT_LINK_EXPIRE_MINUTES: int = 30

    # Optional notification providers.
    SMTP_HOST: str | None = None
    SMTP_PORT: int = 587
    SMTP_USERNAME: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM_EMAIL: str | None = None
    TWILIO_ACCOUNT_SID: str | None = None
    TWILIO_AUTH_TOKEN: str | None = None
    TWILIO_FROM_NUMBER: str | None = None
    TWILIO_WHATSAPP_FROM: str | None = None
    FCM_SERVER_KEY: str | None = None

    # Mobile OTP authentication. In local development the OTP is returned in
    # the response; production must disable dev OTP and use a real provider.
    OTP_DEV_MODE: bool = True
    OTP_EXPIRY_SECONDS: int = 300
    OTP_MAX_ATTEMPTS: int = 5

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.strip().upper() == "PRODUCTION"

    @property
    def cors_origins(self) -> list[str]:
        return [item.strip() for item in self.CORS_ORIGINS.split(",") if item.strip()]

    @property
    def allowed_hosts(self) -> list[str]:
        return [item.strip() for item in self.ALLOWED_HOSTS.split(",") if item.strip()]

    def validate_for_startup(self) -> None:
        """Fail fast on unsafe production configuration.

        Development remains permissive so the existing local workflow is not
        changed. Production is deliberately strict because this application
        handles resident and financial information.
        """
        if not self.is_production:
            return

        secret = self.JWT_SECRET_KEY.strip()
        if len(secret) < 32 or secret.lower() in {
            "safecolonysecret123",
            "changeme",
            "change-me",
            "secret",
        }:
            raise RuntimeError(
                "Production JWT_SECRET_KEY must be a new random secret of at least 32 characters."
            )

        if self.OTP_DEV_MODE:
            raise RuntimeError(
                "OTP_DEV_MODE must be false in production. Configure a real OTP provider."
            )

        if not self.cors_origins:
            raise RuntimeError("CORS_ORIGINS must contain at least one trusted origin in production.")

        if self.allowed_hosts == ["*"]:
            raise RuntimeError("ALLOWED_HOSTS must contain the production API hostname.")

        if "localhost" in self.DATABASE_URL.lower() or "127.0.0.1" in self.DATABASE_URL:
            raise RuntimeError("Production DATABASE_URL must point to the production database, not localhost.")


settings = Settings()
