import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static bool _isInitialized = false;

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  /// Initialize notifications (call this on app startup)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _instance._notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );

    _isInitialized = true;
  }

  /// Send a notification for study session completion
  static Future<void> sendStudyCompletedNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'study_complete',
      'Study Completed',
      channelDescription: 'Notification when study session completes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _instance._notificationsPlugin.show(
      0,
      'Study Session Completed! 🎉',
      'Mr. Plant is very happy that you took care of him!',
      notificationDetails,
    );
  }

  /// Send a notification when break ends
  static Future<void> sendBreakEndedNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'break_ended',
      'Break Ended',
      channelDescription: 'Notification when break time ends',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _instance._notificationsPlugin.show(
      1,
      'Break Ended! ⏰',
      'Time to get back to studying. Let\'s go!',
      notificationDetails,
    );
  }
}
