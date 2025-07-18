// Notification Service
// This service handles scheduling, managing, and cancelling local notifications for medication and appointment reminders.
// It uses flutter_local_notifications and supports exact alarms, custom sounds, and Android notification actions.

import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Local notifications plugin
import 'package:timezone/timezone.dart'
    as tz; // Timezone support for scheduling
import 'dart:io' show Platform; // Platform checks
import 'package:flutter/services.dart'; // For handling platform exceptions

// NotificationService provides static methods for notification management
class NotificationService {
  static final _plugin =
      FlutterLocalNotificationsPlugin(); // Notification plugin instance

  /// Schedules daily reminders at specified times.
  ///
  /// [id] is the base notification ID.
  /// [title] is the notification title.
  /// [body] is the notification body text.
  /// [times] is a list of tz.TZDateTime objects at which the notification should be shown.
  /// [sound] is an optional custom sound resource name.
  /// [actions] is an optional list of custom Android notification actions.
  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required List<tz.TZDateTime> times,
    String? sound,
    List<AndroidNotificationAction>? actions,
  }) async {
    for (int i = 0; i < times.length; i++) {
      final scheduledDateTime = times[i]; // Time for this notification
      final androidDetails = AndroidNotificationDetails(
        'med_reminders', // Channel ID
        'Medication Reminders', // Channel name
        importance: Importance.max, // High importance
        priority: Priority.high, // High priority
        sound: sound != null
            ? RawResourceAndroidNotificationSound(sound) // Custom sound
            : null,
        playSound: true,
        actions: actions, // Custom actions (if any)
      );
      try {
        final details = NotificationDetails(android: androidDetails);
        await _plugin.zonedSchedule(
          id + i, // Unique notification ID
          title, // Notification title
          body, // Notification body
          scheduledDateTime, // When to show
          details, // Notification details
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents:
              DateTimeComponents.time, // Repeat daily at this time
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle, // Exact alarm
          androidAllowWhileIdle: true, // Allow while idle
        );
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          // Handle missing permission for exact alarms
          print(
            'Exact alarms not permitted. Consider prompting the user or falling back to inexact scheduling.',
          );
        } else {
          rethrow; // Rethrow other exceptions
        }
      }
    }
  }

  // Cancels a single notification by ID
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  // Cancels all notifications for a medication (baseId + count)
  static Future<void> cancelAllForMedication(int baseId, int count) async {
    for (int i = 0; i < count; i++) {
      await _plugin.cancel(baseId + i);
    }
  }
}
