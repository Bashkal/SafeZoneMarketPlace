import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/app_navigator.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'default_channel';
  static const String _channelName = 'General Notifications';
  static const String _channelDescription = 'Default channel for app notifications';
  
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create channel
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        final productId = (data['productId'] ?? data['id'] ?? data['product_id'])?.toString();
        if (productId != null && productId.isNotEmpty) {
          AppNavigator.navigatorKey.currentState?.pushNamed(
            '/product',
            arguments: productId,
          );
          return;
        }
      }
    } catch (_) {
      // Ignore malformed payloads
    }
  }

  Future<void> showRemoteNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Don't show notification if current user created this product
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final productUserId = message.data['userId'];
    if (currentUserId != null && productUserId == currentUserId) {
      return; // Skip notification for own products
    }

    await _fln.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}