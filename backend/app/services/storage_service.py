from __future__ import annotations

from datetime import timedelta
from pathlib import Path
from urllib.parse import quote

from app.config import settings


class StorageService:
    """Small storage abstraction with local development and GCS production modes."""

    def __init__(self) -> None:
        self.backend = settings.STORAGE_BACKEND.strip().upper()

        if self.backend == "GCS":
            if not settings.GCS_BUCKET_NAME:
                raise RuntimeError("GCS_BUCKET_NAME is required when STORAGE_BACKEND=GCS.")

            from google.cloud import storage

            self._client = storage.Client()
            self._bucket = self._client.bucket(settings.GCS_BUCKET_NAME)
            self._signer = None
            self._signer_email = None
            try:
                import google.auth
                from google.auth.iam import Signer
                from google.auth.transport.requests import Request

                credentials, _ = google.auth.default()
                service_account_email = getattr(credentials, "service_account_email", None)
                if service_account_email and hasattr(credentials, "sign_bytes"):
                    self._signer = Signer(
                        Request(),
                        credentials,
                        service_account_email,
                    )
                    self._signer_email = service_account_email
            except Exception:
                # Local service-account JSON credentials may already provide
                # sign_bytes. If not, generate_signed_url will fail clearly.
                self._signer = None
                self._signer_email = None
        else:
            self._client = None
            self._bucket = None

    @staticmethod
    def _clean_object_name(object_name: str) -> str:
        return object_name.lstrip("/").replace("\\", "/")

    def upload_bytes(self, object_name: str, content: bytes, content_type: str | None = None) -> str:
        object_name = self._clean_object_name(object_name)

        if self.backend == "GCS":
            blob = self._bucket.blob(object_name)
            blob.upload_from_string(content, content_type=content_type)
            return object_name

        target = Path("uploads") / object_name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        return f"/uploads/{object_name}"

    def read_bytes(self, object_name: str) -> bytes:
        object_name = self._clean_object_name(object_name)

        if self.backend == "GCS":
            return self._bucket.blob(object_name).download_as_bytes()

        local_path = Path("uploads") / object_name
        return local_path.read_bytes()

    def url_for(self, stored_path: str | None) -> str | None:
        if not stored_path:
            return stored_path

        if self.backend != "GCS":
            return stored_path

        # Existing database rows may contain /uploads/... from development.
        # New GCS rows store the object name without the /uploads prefix.
        object_name = stored_path
        if object_name.startswith("/uploads/"):
            object_name = object_name[len("/uploads/") :]

        blob = self._bucket.blob(self._clean_object_name(object_name))

        # Cloud Run uses the service account's IAM SignBlob capability. The
        # google-cloud-storage client will use the configured application
        # credentials when generating a V4 signed URL.
        kwargs = {
            "version": "v4",
            "expiration": timedelta(minutes=settings.GCS_SIGNED_URL_MINUTES),
            "method": "GET",
        }
        if self._signer is not None and self._signer_email:
            kwargs["credentials"] = self._signer
            kwargs["service_account_email"] = self._signer_email

        return blob.generate_signed_url(**kwargs)

    def delete(self, stored_path: str | None) -> None:
        if not stored_path:
            return

        object_name = stored_path
        if object_name.startswith("/uploads/"):
            object_name = object_name[len("/uploads/") :]
        object_name = self._clean_object_name(object_name)

        if self.backend == "GCS":
            blob = self._bucket.blob(object_name)
            if blob.exists():
                blob.delete()
            return

        local_path = Path("uploads") / object_name
        if local_path.exists():
            local_path.unlink()
