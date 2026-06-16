import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  // Callback when notification is tapped
  static void Function(String? postId)? onNotificationTapped;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Extract postId from payload and call the callback
        final postId = response.payload;
        if (postId != null && onNotificationTapped != null) {
          onNotificationTapped!(postId);
        }
      },
    );

    // Request notification permission for Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? postId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cariunpam_notifications',
      'CariUnpam Notifikasi',
      channelDescription: 'Notifikasi balasan dan verifikasi postingan',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6366F1),
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      details,
      payload: postId,
    );
  }
}
