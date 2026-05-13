import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Service for managing FCM push notifications (token-based).
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _vapidKey =
      'BG7qaSaUPwenzt0e2qZrpYB4rrQcnsc0uSlRp8Ul0BaiENKOwk2-HYCwuhC6Brzz7COiZy4YwsUD75krWS0YOJc';

  /// Initialize without requesting permission.
  /// If permission was already granted, stores token and sets up listeners.
  static Future<void> initializeWithoutPermission(
    ScaffoldMessengerState messengerState,
  ) async {
    try {
      final settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _storeFcmToken();
        _listenTokenRefresh();
      }

      _listenForegroundMessages(messengerState);
    } catch (e) {
      debugPrint('NotificationService.initializeWithoutPermission error: $e');
    }
  }

  /// Request notification permission from a user gesture.
  /// Returns true if permission was granted.
  static Future<bool> requestPermissionAndEnable() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return false;
      }

      await _storeFcmToken();
      _listenTokenRefresh();
      return true;
    } catch (e) {
      debugPrint('NotificationService.requestPermissionAndEnable error: $e');
      return false;
    }
  }

  /// Check current permission status without requesting it.
  static Future<bool> isPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('NotificationService.isPermissionGranted error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  static void _listenForegroundMessages(
    ScaffoldMessengerState messengerState,
  ) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      messengerState.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (notification.body != null)
                Text(
                  notification.body!,
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF26A69A),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  static Future<void> _storeFcmToken() async {
    try {
      final token = await _messaging.getToken(vapidKey: _vapidKey);
      if (token == null) return;

      await _updateTokenInFirestore(token);
    } catch (e) {
      debugPrint('NotificationService._storeFcmToken error: $e');
    }
  }

  static void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(newToken);
    });
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
