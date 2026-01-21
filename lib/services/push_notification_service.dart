import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      // ১. পারমিশন রিকোয়েস্ট
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted permission');
      }

      // ২. লোকাল নোটিফিকেশন সেটআপ
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(initSettings);

      // ৩. ফোরগ্রাউন্ড হ্যান্ডলার
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      // ৪. ব্যাকগ্রাউন্ড থেকে ওপেন করলে
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log("Notification clicked: ${message.data}");
      });

    } catch (e) {
      log("Notification init error: $e");
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }
}