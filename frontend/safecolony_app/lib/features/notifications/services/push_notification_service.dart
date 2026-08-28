import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/api/api_client.dart';

/// Handles Android FCM registration and foreground notifications.
///
/// Firebase project values are supplied with --dart-define so the source tree
/// does not contain Firebase credentials. If they are not supplied, push
/// notifications remain disabled but the normal in-app notification inbox
/// continues to work.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'safecolony_notifications',
    'SafeColony Notifications',
    description: 'Important SafeColony community notifications',
    importance: Importance.high,
  );

  bool _initialized = false;
  void Function(Map<String, dynamic> data)? _tapHandler;

  void setNotificationTapHandler(void Function(Map<String, dynamic> data) handler) {
    _tapHandler = handler;
  }

  void _handleTapPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _tapHandler?.call(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    // Android displays FCM notification payloads automatically while the app
    // is backgrounded/terminated. We intentionally avoid showing a second
    // local notification here to prevent duplicates.
    if (kDebugMode) {
      debugPrint(
        'SafeColony background push: ${message.messageId} ${message.notification?.title}',
      );
    }
  }

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      // The same physical device can be used by different SafeColony users.
      // If Firebase/local notifications are already initialized, still
      // re-register the current FCM token so the backend associates the token
      // with the newly logged-in user.
      if (_initialized) {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          await _registerToken(token);
        }
        return;
      }

      await _initializeFirebase();
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          _handleTapPayload(response.payload);
        },
      );

      final androidPlugin =
          _local.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _tapHandler?.call(Map<String, dynamic>.from(message.data));
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // Delay until the host application's navigator is ready.
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          _tapHandler?.call(Map<String, dynamic>.from(initialMessage.data));
        });
      }

      _messaging.onTokenRefresh.listen((token) async {
        if (token.isNotEmpty) {
          await _registerToken(token);
        }
      });

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }

      _initialized = true;
      if (kDebugMode) debugPrint('SafeColony push notifications initialized');
    } catch (e, st) {
      // Push must never prevent a user from logging into the application.
      if (kDebugMode) {
        debugPrint('SafeColony push initialization failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  Future<void> _initializeFirebase() async {
    // Preferred Android configuration: google-services.json + the Google
    // Services Gradle plugin. This is the normal Firebase setup for a Flutter
    // Android app and avoids putting Firebase config in build commands.
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (nativeError) {
        // Keep a dart-define fallback for environments where google-services.json
        // is intentionally not packaged (for example a CI build).
        const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
        const appId = String.fromEnvironment('FIREBASE_APP_ID');
        const messagingSenderId =
            String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
        const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
        const storageBucket =
            String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

        if (apiKey.isEmpty ||
            appId.isEmpty ||
            messagingSenderId.isEmpty ||
            projectId.isEmpty) {
          throw StateError(
            'Firebase Android configuration is missing. Add '
            'android/app/google-services.json, or provide Firebase '
            'dart-defines. Native initialization error: $nativeError',
          );
        }

        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            storageBucket: storageBucket.isEmpty ? null : storageBucket,
          ),
        );
      }
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  Future<void> _registerToken(String token) async {
    try {
      await ApiClient.dio.post(
        '/notifications/devices',
        data: {
          'token': token,
          'platform': 'ANDROID',
        },
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SafeColony FCM token registration failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await ApiClient.dio.post(
        '/notifications/devices/unregister',
        data: {'token': token},
      );
    } catch (e, st) {
      // Logout must still succeed even if the network is unavailable.
      if (kDebugMode) {
        debugPrint('SafeColony FCM token unregister failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = Map<String, dynamic>.from(message.data);
    final isChat = (data['type'] ?? data['entity_type'] ?? '').toString().toUpperCase() == 'CHAT';
    // Keep one foreground chat notification instead of creating a new row
    // for every message. Android background pushes use the same chat tag.
    final notificationId = isChat ? 700001 : notification.hashCode;
    await _local.show(
      notificationId,
      notification.title ?? 'SafeColony',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'safecolony_notifications',
          'SafeColony Notifications',
          channelDescription:
              'Important SafeColony community notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          groupKey: isChat
              ? 'safecolony_community_chat'
              : 'safecolony_notifications',
          setAsGroupSummary: false,
        ),
      ),
      payload: jsonEncode(data),
    );
  }
}
