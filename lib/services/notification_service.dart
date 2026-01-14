
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize notifications (call this on app startup)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _instance.flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 User tapped: {details.payload}");
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _instance.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create the v5 channel for settings
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mr_plannter_v5',
      'Task Notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation?.createNotificationChannel(channel);

    await _instance.requestPermissions();
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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

    await _instance.flutterLocalNotificationsPlugin.show(
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

    await _instance.flutterLocalNotificationsPlugin.show(
      1,
      'Break Ended! ⏰',
      'Time to get back to studying. Let\'s go!',
      notificationDetails,
    );
  }

  // --- SCHEDULING LOGIC FROM DATA FOLDER ---
  Future<void> scheduleDistributedNotifications({
    required int taskId,
    required String title,
    required DateTime eventDate,
    required String eventTimeStr,
    required int count,
    required int daysBefore,
    required bool isDeadline,
  }) async {
    final timeParts = eventTimeStr.split(':');
    final fullEventDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    debugPrint("📅 Target Event: $fullEventDate");

    DateTime startTime;
    if (daysBefore > 0) {
      startTime = fullEventDate.subtract(Duration(days: daysBefore));
    } else {
      startTime = DateTime.now().add(const Duration(seconds: 5));
    }

    if (startTime.isAfter(fullEventDate)) {
      startTime = DateTime.now();
    }

    if (count > 1) {
      final totalSeconds = fullEventDate.difference(startTime).inSeconds;
      final stepSeconds = (totalSeconds > 0) ? totalSeconds ~/ (count - 1) : 0;

      debugPrint("📐 Distribution: Total Seconds: $totalSeconds, Step: $stepSeconds sec");

      for (int i = 0; i < count; i++) {
        DateTime triggerTime;

        if (i == 0) {
          triggerTime = startTime;
        } else if (i == count - 1) {
          triggerTime = fullEventDate;
        } else {
          triggerTime = startTime.add(Duration(seconds: stepSeconds * i));
        }

        if (triggerTime.isAfter(DateTime.now())) {
          await _scheduleSingleNotification(
            id: taskId * 1000 + i,
            title: isDeadline ? "Time for your Deadline: $title" : "Time for your task: $title",
            body: "${i + 1}/$count - Scheduled for: ${_formatDate(fullEventDate)}",
            triggerTime: triggerTime,
          );
        }
      }
    } else {
      final triggerTime = (daysBefore == 0) ? startTime : fullEventDate;

      if (triggerTime.isAfter(DateTime.now())) {
        await _scheduleSingleNotification(
          id: taskId * 1000,
          title: isDeadline ? "Time for your Deadline: $title" : "Time for your task: $title",
          body: "Scheduled for: ${_formatDate(fullEventDate)}",
          triggerTime: triggerTime,
        );
      }
    }

    if (isDeadline && fullEventDate.isAfter(DateTime.now())) {
      await _scheduleSingleNotification(
        id: taskId * 1000 + 999,
        title: "Deadline Expired!",
        body: "Your Deadline: $title expired!",
        triggerTime: fullEventDate.add(const Duration(seconds: 5)),
        isExpiry: true,
      );
    }
  }

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime triggerTime,
    bool isExpiry = false,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(triggerTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            isExpiry ? 'deadline_expiry_v5' : 'mr_plannter_v5',
            isExpiry ? 'Deadline Expiry' : 'Task Notifications',
            importance: Importance.max,
            priority: Priority.high,
            color: isExpiry ? Colors.red : Colors.blue,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("✅ Scheduled ID:$id at $triggerTime");
    } catch (e) {
      debugPrint("❌ Error scheduling: $e");
    }
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}";
  }
}

// --- POP-UP UI ---
Future<void> showNotificationSetupDialog(
  BuildContext context, 
  int taskId, 
  String title, 
  String dateStr,
  String timeStr,
  bool isDeadline
) async {
  int count = 1;
  int days = 0;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
             Icon(isDeadline ? Icons.timer_off : Icons.notifications_active, color: Colors.blue.shade900),
             const SizedBox(width: 10),
             Text(isDeadline ? "Deadline Setup" : "Task Setup", style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("For: \n$title", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("How many times?"),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => count > 1 ? count-- : null)),
                    Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => count++)),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Days before?"),
                    Text("(0 = Start Now)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => days > 0 ? days-- : null)),
                    Text("$days", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => days++)),
                  ],
                ),
              ],
            ),
             Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                days == 0 
                  ? "🔔 Will notify from NOW until the task!" 
                  : "🔔 Will notify starting $days day(s) before.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
              ),
            ),
            if (isDeadline)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text("+ Expiry notification", style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Skip")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
            onPressed: () {
              NotificationService().scheduleDistributedNotifications(
                taskId: taskId,
                title: title,
                eventDate: DateTime.parse(dateStr),
                eventTimeStr: timeStr,
                count: count,
                daysBefore: days,
                isDeadline: isDeadline,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Notifications scheduled!")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    ),
  );
}
