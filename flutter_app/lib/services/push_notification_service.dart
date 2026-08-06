import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
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

    // Request permission (shows iOS dialog)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[PUSH] Permission: ${settings.authorizationStatus}');
    }

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
  }

  /// Call after user logs in to register the device token
  static Future<void> registerDevice() async {
    if (kIsWeb) return; // Push notifications not configured for web
    // Retry getting FCM token — on iOS it can take a moment after APNs is ready
    for (int i = 0; i < 5; i++) {
      try {
        final token = await _messaging.getToken();
        if (kDebugMode) print('[PUSH] FCM token attempt ${i + 1}: ${token != null ? token.substring(0, 20) + "..." : "null"}');
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
