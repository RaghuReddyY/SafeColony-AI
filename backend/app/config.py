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
    GEMINI_MODEL: str = "gemini-3.6-flash"

    # SafeColony displays resident-facing AI dates/times in India time and
    # monetary values in Indian Rupees. Database timestamps remain UTC.
    APP_TIMEZONE: str = "Asia/Kolkata"
    CURRENCY_CODE: str = "INR"
    CURRENCY_SYMBOL: str = "₹"

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
    EMAIL_VERIFICATION_BASE_URL: str | None = None
    EMAIL_VERIFICATION_EXPIRY_MINUTES: int = 30
    PASSWORD_RESET_EXPIRY_MINUTES: int = 30
    PASSWORD_RESET_DEV_MODE: bool = False
    TWILIO_ACCOUNT_SID: str | None = None
    TWILIO_AUTH_TOKEN: str | None = None
    TWILIO_FROM_NUMBER: str | None = None
    TWILIO_WHATSAPP_FROM: str | None = None
    FCM_SERVER_KEY: str | None = None
    # Preferred Firebase HTTP v1 configuration. Store the JSON in Secret Manager
    # and expose it to Cloud Run as FCM_SERVICE_ACCOUNT_JSON.
    FCM_SERVICE_ACCOUNT_JSON: str | None = None
    # Cloud Run uses Application Default Credentials from its runtime service
    # account. This is the Firebase/Google Cloud project used by SafeColony.
    FCM_PROJECT_ID: str | None = "safecolony-production"

    # Mobile OTP login is intentionally disabled until a production SMS
    # provider and the final mobile-login flow are approved. Delivery OTPs
    # are separate and remain enabled.
    OTP_ENABLED: bool = False
    OTP_DEV_MODE: bool = False
    OTP_EXPIRY_SECONDS: int = 300
    OTP_MAX_ATTEMPTS: int = 5

    # Runtime scheduling. Keep enabled for local development; disable it on
    # Cloud Run and invoke jobs through Cloud Scheduler/Run Jobs instead.
    RUN_IN_PROCESS_SCHEDULER: bool = True
    SCHEDULER_SECRET: str | None = None

    # File storage. LOCAL preserves the current development behaviour. GCS is
    # used in production so uploads survive Cloud Run instance replacement.
    STORAGE_BACKEND: str = "LOCAL"
    GCS_BUCKET_NAME: str | None = None
    GCS_SIGNED_URL_MINUTES: int = 15

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

        if self.OTP_ENABLED:
            if self.OTP_DEV_MODE:
                raise RuntimeError(
                    "OTP_DEV_MODE must be false in production when mobile OTP is enabled."
                )
            sms_configured = (
                bool(self.TWILIO_ACCOUNT_SID)
                and bool(self.TWILIO_AUTH_TOKEN)
                and bool(self.TWILIO_FROM_NUMBER)
            )
            if not sms_configured:
                raise RuntimeError(
                    "Mobile OTP is enabled in production but the Twilio SMS provider is not configured."
                )

        if not self.cors_origins:
            raise RuntimeError("CORS_ORIGINS must contain at least one trusted origin in production.")

        if self.allowed_hosts == ["*"]:
            raise RuntimeError("ALLOWED_HOSTS must contain the production API hostname.")
        if any(host.lower() in {"localhost", "127.0.0.1", "0.0.0.0"} for host in self.allowed_hosts):
            raise RuntimeError("Production ALLOWED_HOSTS must not contain local development hosts.")

        if any(
            origin.lower().split("/")[-1].split(":")[0] in {"localhost", "127.0.0.1"}
            for origin in self.cors_origins
        ):
            raise RuntimeError("Production CORS_ORIGINS must not contain localhost or 127.0.0.1.")

        if "localhost" in self.DATABASE_URL.lower() or "127.0.0.1" in self.DATABASE_URL:
            raise RuntimeError("Production DATABASE_URL must point to the production database, not localhost.")

        if self.STORAGE_BACKEND.strip().upper() != "GCS":
            raise RuntimeError("Production STORAGE_BACKEND must be GCS.")

        if not self.GCS_BUCKET_NAME or not self.GCS_BUCKET_NAME.strip():
            raise RuntimeError("GCS_BUCKET_NAME must be configured in production.")

        if self.RUN_IN_PROCESS_SCHEDULER:
            raise RuntimeError(
                "RUN_IN_PROCESS_SCHEDULER must be false in production; use Cloud Scheduler/Cloud Run Jobs."
            )

        if not self.SCHEDULER_SECRET or len(self.SCHEDULER_SECRET.strip()) < 32:
            raise RuntimeError("SCHEDULER_SECRET must be a new random secret of at least 32 characters.")


settings = Settings()
