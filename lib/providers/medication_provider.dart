/// This file manages the state and business logic for medication tracking in the MyMedBuddy app.
/// It handles adding, updating, and deleting medications, scheduling reminders,
/// recording whether medications were taken or missed, and computing compliance streaks.

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../main.dart' as app_main;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MedicationProvider extends ChangeNotifier {
  final List<Medication> _medications = [];
  bool _tzInitialized = false;

  List<Medication> get medications => _medications;

  MedicationProvider() {
    init();
  }

  // Calculates the current streak of fully taken medications by checking each past day.
  int calculateStreak(Medication med) {
    int streak = 0;
    DateTime today = DateTime.now();
    while (true) {
      String dateStr = today.toIso8601String().split('T')[0];
      final times = med.times;
      final takenMap = med.takenHistory[dateStr] ?? {};
      bool allTaken =
          times.isNotEmpty && times.every((t) => takenMap[t] == true);
      if (allTaken) {
        streak++;
        today = today.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  void _recalculateStreaks() {
    for (int i = 0; i < _medications.length; i++) {
      final med = _medications[i];
      final newStreak = calculateStreak(med);
      _medications[i] = med.copyWith(streak: newStreak);
    }
  }

  // Initializes the time zone database if not already initialized (for scheduling notifications correctly).
  Future<void> _ensureTimeZonesInitialized() async {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  Future<void> init() async {
    await _ensureTimeZonesInitialized();
    await loadMedications();
    _recalculateStreaks();
  }

  // Adds a new medication, saves it, and schedules notifications for doses due within the next hour.
  Future<void> addMedication(Medication med) async {
    await _ensureTimeZonesInitialized();
    _medications.add(med);
    saveMedications();
    // Schedule notification for any dose within 1 hour
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    for (final time in med.times) {
      final timeParts = time.split(":");
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;
        final medDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        final diff = medDateTime.difference(now);
        // Schedule a notification only if the dose is within the next hour.
        if (diff.inMinutes > 0 && diff.inMinutes <= 60) {
          await app_main.flutterLocalNotificationsPlugin.zonedSchedule(
            med.id.hashCode ^ time.hashCode,
            'Medication Reminder',
            'Time to take ${med.name} (${med.dosage}) at $time',
            tz.TZDateTime.from(medDateTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'medication_channel',
                'Medications',
                channelDescription: 'Reminders for taking medication',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
    _recalculateStreaks();
    notifyListeners();
  }

  // Updates an existing medication, reschedules notifications, and saves the changes.
  Future<void> updateMedication(Medication med) async {
    final index = _medications.indexWhere((m) => m.id == med.id);
    if (index != -1) {
      await _ensureTimeZonesInitialized();
      // Cancel all previous notifications for this med
      for (final timeStr in med.times) {
        NotificationService.cancelNotification((med.id + timeStr).hashCode);
      }
      // Schedule new reminders for each time
      final now = tz.TZDateTime.now(tz.local);
      for (final timeStr in med.times) {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1].split(' ')[0]) ?? 0;
        final scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        NotificationService.scheduleDailyReminder(
          id: (med.id + timeStr).hashCode,
          title: 'Take your medication',
          body: '${med.name} - ${med.dosage} at $timeStr',
          times: [scheduledTime],
        );
      }
      _medications[index] = med;
      saveMedications();
      _recalculateStreaks();
      notifyListeners();
    }
  }

  // Removes a medication by its ID or index and cancels its notifications.
  void removeMedicationById(String id) {
    _medications.removeWhere((med) => med.id == id);
    NotificationService.cancelNotification(id.hashCode);
    saveMedications();
    notifyListeners();
  }

  // Removes a medication by its ID or index and cancels its notifications.
  void removeMedication(int index) {
    if (index >= 0 && index < _medications.length) {
      final id = _medications[index].id;
      NotificationService.cancelNotification(id.hashCode);
      _medications.removeAt(index);
      saveMedications();
      notifyListeners();
    }
  }

  // Marks a specific medication dose as taken/missed and updates streaks accordingly.
  void markTakenForDate(String id, DateTime date, String time) {
    final index = _medications.indexWhere((med) => med.id == id);
    if (index != -1) {
      final dateStr = date.toIso8601String().split('T')[0];
      final updatedHistory = Map<String, Map<String, bool>>.from(
        _medications[index].takenHistory,
      );
      final timeMap = Map<String, bool>.from(updatedHistory[dateStr] ?? {});
      timeMap[time] = true;
      updatedHistory[dateStr] = timeMap;
      _medications[index] = _medications[index].copyWith(
        takenHistory: updatedHistory,
      );
      saveMedications();
      _recalculateStreaks();
      notifyListeners();
    }
  }

  // Marks a specific medication dose as taken/missed and updates streaks accordingly.
  void markMissedForDate(String id, DateTime date, String time) {
    final index = _medications.indexWhere((med) => med.id == id);
    if (index != -1) {
      final dateStr = date.toIso8601String().split('T')[0];
      final updatedHistory = Map<String, Map<String, bool>>.from(
        _medications[index].takenHistory,
      );
      final timeMap = Map<String, bool>.from(updatedHistory[dateStr] ?? {});
      timeMap[time] = false;
      updatedHistory[dateStr] = timeMap;
      _medications[index] = _medications[index].copyWith(
        takenHistory: updatedHistory,
      );
      saveMedications();
      _recalculateStreaks();
      notifyListeners();
    }
  }

  // Marks a specific medication dose as taken/missed and updates streaks accordingly.
  void toggleTaken(String id, String time) {
    final index = _medications.indexWhere((med) => med.id == id);
    if (index != -1) {
      final today = DateTime.now();
      final dateStr = today.toIso8601String().split('T')[0];
      final med = _medications[index];
      final updatedHistory = Map<String, Map<String, bool>>.from(
        med.takenHistory,
      );
      final timeMap = Map<String, bool>.from(updatedHistory[dateStr] ?? {});
      final taken = timeMap[time] ?? false;
      timeMap[time] = !taken;
      updatedHistory[dateStr] = timeMap;
      _medications[index] = med.copyWith(takenHistory: updatedHistory);
      saveMedications();
      _recalculateStreaks();
      notifyListeners();
    }
  }

  // Persists or loads the medication list using SharedPreferences.
  Future<void> saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedMeds = _medications
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    await prefs.setStringList('medications', encodedMeds);
  }

  // Persists or loads the medication list using SharedPreferences.
  Future<void> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? medList = prefs.getStringList('medications');
    if (medList != null) {
      _medications.clear();
      _medications.addAll(
        medList.map((m) => Medication.fromJson(jsonDecode(m))),
      );
      _recalculateStreaks();
      notifyListeners();
    }
  }
}
