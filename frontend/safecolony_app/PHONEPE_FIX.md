# SafeColony PhonePe launch fix

The maintenance button now copies the configured UPI ID and launches the installed PhonePe app directly on Android. It does NOT send a pre-filled UPI payment intent.

Files changed:
- lib/features/maintenance/screens/maintenance_resident_screen.dart
- android/app/src/main/kotlin/com/safecolony/app/MainActivity.kt
- android/app/src/main/AndroidManifest.xml

The Android implementation uses the PhonePe package `com.phonepe.app` and a Flutter MethodChannel, so no new Flutter package dependency is required.
