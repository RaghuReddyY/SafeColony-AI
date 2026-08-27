# SafeColony backend push configuration

The notification backend already has device registration and an outbox.
This update adds Firebase Cloud Messaging HTTP v1 support and immediate PUSH
delivery from the notification creation path.

Preferred Cloud Run environment:

FCM_SERVICE_ACCOUNT_JSON=<service-account-json-from-secret-manager>
FCM_PROJECT_ID=<firebase-project-id>

`FCM_SERVER_KEY` remains supported as a legacy fallback.

The backend does not require the Firebase Android configuration file. Firebase
Android configuration belongs to the Flutter app.
