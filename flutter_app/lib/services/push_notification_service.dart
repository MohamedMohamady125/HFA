import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

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
      print('Push permission: ${settings.authorizationStatus}');
    }

    // Get APNs token first (iOS only)
    await _messaging.getAPNSToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message: ${message.notification?.title} - ${message.notification?.body}');
      }
    });
  }

  /// Call after user logs in to register the device token
  static Future<void> registerDevice() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token != _lastRegisteredToken) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to get FCM token: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiService().post('/notifications/register-device', data: {
        'token': token,
        'platform': defaultTargetPlatform.name,
      });
      _lastRegisteredToken = token;
      if (kDebugMode) print('FCM token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      if (kDebugMode) print('Failed to register FCM token: $e');
    }
  }
}
