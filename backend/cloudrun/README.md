# SafeColony - Google Cloud deployment notes

Target:
- Cloud Run: `asia-south1` (Mumbai)
- Cloud SQL for PostgreSQL: `asia-south1`
- Cloud Storage: private bucket in `asia-south1`
- API custom domain: `https://api.safecolony.in`

## 1. Build the backend image

Run from `backend/`:

```bash
gcloud builds submit --tag asia-south1-docker.pkg.dev/PROJECT_ID/safecolony/backend:VERSION .
```

## 2. Run database migrations

Do this as a controlled deployment step/Cloud Run Job, not in the web service startup:

```bash
gcloud run jobs execute safecolony-migrate \
  --region=asia-south1 \
  --wait
```

The migration job should use the same image and production `DATABASE_URL`.

## 3. Deploy the API

Important production environment:
- `APP_ENV=PRODUCTION`
- `RUN_IN_PROCESS_SCHEDULER=false`
- `STORAGE_BACKEND=GCS`
- `GCS_BUCKET_NAME=<private-bucket>`
- `ALLOWED_HOSTS=api.safecolony.in`
- `CORS_ORIGINS=<trusted web origins>`
- `OTP_DEV_MODE=false`

Store secrets in Secret Manager and inject them into Cloud Run:
- `DATABASE_URL`
- `JWT_SECRET_KEY`
- `GEMINI_API_KEY`
- `SCHEDULER_SECRET`
- payment/SMTP/Twilio secrets when used

## 4. Scheduled jobs

Create Cloud Scheduler jobs that POST to:

```text
/internal/scheduler/notification
/internal/scheduler/vacation
/internal/scheduler/maintenance
```

Send the `X-SafeColony-Scheduler-Secret` header from Secret Manager.

Schedules matching the current development behaviour:
- notification: every 5 minutes
- vacation: every 5 minutes
- maintenance: every hour

Do not enable the in-process APScheduler on Cloud Run.

## 5. Storage

Keep the GCS bucket private. SafeColony generates short-lived signed URLs for incident evidence. Visitor QR images are served through the SafeColony API using the visitor's QR token.

Do not make the bucket public.

## 6. Custom domain

Map:

```text
api.safecolony.in
```

to the Cloud Run service and complete the DNS records shown by Google Cloud. Keep HTTPS enabled.

## 7. Flutter production build

After the API is live and verified:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.safecolony.in
```
