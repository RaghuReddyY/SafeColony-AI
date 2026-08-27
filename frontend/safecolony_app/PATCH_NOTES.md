# SafeColony fixes - 2026-08-27

This archive was produced from the latest uploaded backend and android/lib source.

FIXES:
1. API timestamps that are stored as UTC-naive database values are now emitted
   as explicit UTC by the notification API, and Flutter parses timezone-less
   API timestamps as UTC before displaying them in the device's local timezone.
   This fixes the 5:30-hour time offset problem across timestamp-based screens.
2. The actual Android launcher activity (com.safecolony.app.MainActivity) now
   implements the safecolony/native_apps MethodChannel used by Flutter to open
   the PhonePe app. The duplicate unused MainActivity was removed.
3. Maintenance periods now support PUT /maintenance/periods/{id} and
   DELETE /maintenance/periods/{id}. Only DRAFT periods can be edited/deleted;
   periods with bills/expenses or published/closed status are protected.
4. Flutter maintenance admin UI now exposes Edit Period and Delete Period
   actions for DRAFT periods.

FCM:
The current project already has roles/firebasecloudmessaging.admin on
safecolony-runtime, so no IAM change is included.

IMPORTANT:
- The uploaded frontend archive contained android/ and lib/ but not pubspec.yaml
  or the full project root. Keep your existing pubspec.yaml, assets, and other
  root files; extract this archive over the matching SafeColony project root.
- The backend .env was intentionally not included. Keep your existing local
  .env/Cloud Run Secret Manager configuration.
- Backend syntax was validated with Python compileall.
- Flutter/Dart was not executed in this environment; run flutter analyze and
  flutter build apk --release on the Windows development machine.

Recommended verification:
  python -m py_compile app\services\notification_providers.py
  flutter pub get
  flutter analyze
  flutter build apk --release --dart-define=API_BASE_URL=<your Cloud Run URL>
