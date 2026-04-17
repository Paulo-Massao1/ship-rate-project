import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service for managing FCM push notifications.
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _topic = 'all_pilots';

  /// Request permission, check user preference, subscribe/unsubscribe, store token.
  /// Call this after successful login.
  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      await _storeFcmToken();

      final wantsPush = await _getUserPushPreference();
      if (wantsPush) {
        await _subscribeToTopic();
      } else {
        await _messaging.unsubscribeFromTopic(_topic);
      }
    } catch (e) {
      debugPrint('NotificationService.initialize error: $e');
    }
  }

  /// Subscribe to the all_pilots topic.
  static Future<void> subscribeToTopic() async {
    await _subscribeToTopic();
  }

  /// Unsubscribe from the all_pilots topic.
  static Future<void> unsubscribeFromTopic() async {
    try {
      await _messaging.unsubscribeFromTopic(_topic);
    } catch (e) {
      debugPrint('NotificationService.unsubscribeFromTopic error: $e');
    }
  }

  /// Listen for foreground messages and show a SnackBar.
  static void listenForegroundMessages(ScaffoldMessengerState messengerState) {
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

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  static Future<bool> _getUserPushPreference() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data == null || !data.containsKey('pushNotifications')) return true;
    return data['pushNotifications'] == true;
  }

  static Future<void> _subscribeToTopic() async {
    try {
      if (kIsWeb) {
        // On web, topic subscription is handled server-side via token.
        // We store the token and the Cloud Function can use it.
        // For web, we use the token-based approach.
        // However, FCM web does support topic subscription via server SDK.
        // For simplicity, we attempt direct subscription (works on mobile).
        // On web, this may silently fail — push still works via token.
      }
      await _messaging.subscribeToTopic(_topic);
    } catch (e) {
      debugPrint('NotificationService._subscribeToTopic error: $e');
    }
  }

  static Future<void> _storeFcmToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: null,
      );
      if (token == null) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('NotificationService._storeFcmToken error: $e');
    }
  }
}
