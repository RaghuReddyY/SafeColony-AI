# SafeColony mobile push notifications

The project now contains the complete FCM registration/delivery flow.

## 1. Create/configure Firebase Android app

In Firebase Console, use the same Firebase project that will own SafeColony push notifications.

Add an Android app with:

- Package name: `com.safecolony.app`

Collect these values from the Firebase project:

- API key
- Android app ID
- Messaging sender ID
- Project ID
- Storage bucket (if shown)

The source code intentionally does not contain Firebase credentials.

## 2. Build the Android AAB with Firebase values

From `frontend/safecolony_app`:

```powershell
flutter clean
flutter pub get

flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://YOUR-CLOUD-RUN-URL `
  --dart-define=FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
```

The version has been incremented to `1.0.0+4`.

Android 13+ notification permission is requested after successful authentication.

## 3. Configure backend FCM HTTP v1

Preferred production configuration is a Firebase service account.

Create/download a service-account JSON from Firebase/Google Cloud for the Firebase project. Store it in Secret Manager rather than committing it to Git.

Configure Cloud Run with:

- `FCM_SERVICE_ACCOUNT_JSON` = complete service-account JSON
- `FCM_PROJECT_ID` = Firebase project ID

The backend also keeps the existing `FCM_SERVER_KEY` fallback for older deployments, but HTTP v1 is preferred.

## 4. What happens after deployment

1. User logs in.
2. SafeColony requests notification permission.
3. Firebase creates an FCM token.
4. SafeColony registers the token at `POST /notifications/devices`.
5. When a PUSH notification is created, Cloud Run attempts delivery immediately.
6. Failed deliveries remain in the existing notification outbox for retry.
7. Foreground messages use the SafeColony notification channel.
8. Background/terminated Android messages are displayed by FCM.
9. The existing in-app `/notifications/me` inbox remains unchanged.

## Important

Do not put the Firebase service-account JSON, FCM server key, API keys, or Cloud Run secrets into the source ZIP or Git repository.
