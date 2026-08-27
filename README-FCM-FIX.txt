SafeColony FCM Cloud Run fix
==============================

Problem found in the uploaded backend:
Cloud Run logs showed:
  FCM provider is not configured. Set FCM_SERVICE_ACCOUNT_JSON (preferred) or FCM_SERVER_KEY.

The backend previously required an explicit FCM service-account JSON or legacy server key.
The uploaded project already has google-auth installed and Cloud Run already uses:
  safecolony-runtime@safecolony-production.iam.gserviceaccount.com

This fix makes the FCM HTTP v1 provider use Google Application Default Credentials
(ADC) automatically on Cloud Run. FCM_SERVICE_ACCOUNT_JSON remains supported as an
optional fallback for local/non-Google deployments.

Files to replace:
  backend/app/services/notification_providers.py
  backend/app/config.py

IMPORTANT CLOUD RUN IAM STEP
The Cloud Run runtime service account must be allowed to send FCM messages.
Run in PowerShell:

gcloud projects add-iam-policy-binding safecolony-production `
  --member="serviceAccount:safecolony-runtime@safecolony-production.iam.gserviceaccount.com" `
  --role="roles/firebasecloudmessaging.admin"

Then redeploy the backend.

Example deployment from backend directory:
gcloud run deploy safecolony-backend `
  --source . `
  --region=asia-south1 `
  --project=safecolony-production

After deployment, verify:
gcloud run services describe safecolony-backend `
  --region=asia-south1 `
  --project=safecolony-production `
  --format="value(spec.template.spec.serviceAccountName)"

Then create a new SafeColony notification and check:
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="safecolony-backend" AND textPayload:"push"' `
  --project=safecolony-production `
  --limit=20 `
  --order=desc `
  --format="value(timestamp,textPayload)"

Expected result: no "FCM provider is not configured" error. A successful delivery
should move the PUSH delivery to DELIVERED.

No Firebase private-key JSON is required for Cloud Run with this approach.
The Android google-services.json remains the client-side Firebase configuration
and is not a replacement for server authorization.
