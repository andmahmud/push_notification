import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:test/notification_screen.dart';

class FcmService {
  /// Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Local Notification instance
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 🔹 Initialize everything
  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        // You can also save the token to your server here if needed
      } else {
        if (kDebugMode) {
          print('FCM Token is null. Firebase may not be ready yet.');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
        print(stackTrace);
      }
      // Optional: schedule a retry after some delay
    }

    await _initLocalNotification();

    _initPushNotifications();
  }

  Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combined init settings for all platforms (here only Android)
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    // 🔹 Correct initialize call
    await _localNotifications.initialize(
      settings: initSettings, // ✅ required named parameter
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Get.to(() => NotificationsScreen());
      },
    );

    // 🔹 Create Android notification channel (important)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// 🔹 Handle notification navigation
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    Get.to(() => NotificationsScreen(), arguments: message);
  }

  /// 🔹 Show notification when app is foreground
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = notification?.android;

    if (notification == null || android == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// 🔹 Push notification handlers
  void _initPushNotifications() {
    //  App terminated → open from notification
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    // App background → tap notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App foreground → show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });
  }

  // Must be a top-level function
  @pragma('vm:entry-point')
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Initialize FlutterLocalNotificationsPlugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotifications.initialize(
      settings: initSettings, // ✅ this is correct
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Get.to(() => NotificationsScreen());
      },
    );

    // Show local notification
    final notification = message.notification;
    if (notification != null && notification.android != null) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}
