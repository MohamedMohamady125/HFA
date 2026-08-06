import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'deep_link.dart';
import 'refresh_bus.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: just ensures background messages are received
}

class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static String? _lastRegisteredToken;

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Android: create the high-importance channel the backend targets so
    // notifications get heads-up banners, sound, vibration and wake the screen.
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifications',
        description: 'Academy notifications (messages, attendance, gear)',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Request permission (shows iOS dialog)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[PUSH] Permission: ${settings.authorizationStatus}');
    }

    // iOS: show banner + play sound even while the app is in the foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // On iOS, wait for APNs token — retry up to 10 times
    if (Platform.isIOS) {
      String? apnsToken;
      for (int i = 0; i < 10; i++) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) break;
        if (kDebugMode) print('[PUSH] Waiting for APNs token... attempt ${i + 1}');
        await Future.delayed(const Duration(seconds: 2));
      }
      if (kDebugMode) print('[PUSH] APNs token: ${apnsToken != null ? "received" : "NOT received"}');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) print('[PUSH] Token refreshed');
      _sendTokenToBackend(token);
    });

    // Handle foreground messages — refresh open screens so new data
    // (e.g. thread messages) appears immediately.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[PUSH] Foreground: ${message.notification?.title} - ${message.notification?.body}');
      }
      RefreshBus.notify();
    });

    // Tapping a notification while the app is in the background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Tapping a notification that cold-started the app.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    if (kDebugMode) print('[PUSH] Notification tapped, type=$type');
    if (type is String && type.isNotEmpty) DeepLink.set(type);
    RefreshBus.notify();
  }

  /// Re-send the device token (e.g. after a language change so the
  /// server stores the new push language).
  static Future<void> forceReRegister() async {
    _lastRegisteredToken = null;
    await registerDevice();
  }

  /// Call after user logs in to register the device token
  static Future<void> registerDevice() async {
    if (kIsWeb) return; // Push notifications not configured for web
    // Retry getting FCM token — on iOS it can take a moment after APNs is ready
    for (int i = 0; i < 5; i++) {
      try {
        final token = await _messaging.getToken();
        if (kDebugMode) print('[PUSH] FCM token attempt ${i + 1}: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
        if (token != null) {
          if (token != _lastRegisteredToken) {
            await _sendTokenToBackend(token);
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) print('[PUSH] FCM token error: $e');
      }
      await Future.delayed(const Duration(seconds: 3));
    }
    if (kDebugMode) print('[PUSH] Failed to get FCM token after 5 attempts');
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_locale') ?? 'en';
      await ApiService().post('/notifications/register-device', data: {
        'token': token,
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'lang': lang,
      });
      _lastRegisteredToken = token;
      if (kDebugMode) print('[PUSH] Token registered with backend (lang=$lang)');
    } catch (e) {
      if (kDebugMode) print('[PUSH] Failed to register token: $e');
    }
  }
}
