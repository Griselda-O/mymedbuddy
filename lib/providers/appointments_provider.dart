// This file manages appointment data and notification scheduling in the MyMedBuddy app.
// It includes the Appointment model and a Provider (AppointmentsProvider) for state management.

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../main.dart' as app_main;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

/// Represents a user's medical appointment.
/// Includes optional notification support and details like time, location, and doctor.
class Appointment {
  final String id;
  final String title;
  final DateTime dateTime;
  final String doctor;
  final String purpose;
  final String location;
  final String notes;
  final bool reminder;

  Appointment({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.doctor,
    required this.purpose,
    required this.location,
    required this.notes,
    required this.reminder,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dateTime': dateTime.toIso8601String(),
    'doctor': doctor,
    'purpose': purpose,
    'location': location,
    'notes': notes,
    'reminder': reminder,
  };

  static Appointment fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      dateTime:
          DateTime.tryParse(json['dateTime']?.toString() ?? '') ??
          DateTime.now(),
      doctor: json['doctor']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      reminder: json['reminder'] is bool ? json['reminder'] : false,
    );
  }
}

/// Manages the list of appointments.
/// Provides functionality to add, remove, update, and load appointments from local storage.
/// Also handles scheduling notifications for upcoming appointments.
class AppointmentsProvider extends ChangeNotifier {
  final List<Appointment> _appointments = [];

  List<Appointment> get appointments => _appointments;

  // Filters appointments to show only those happening this week or month.
  List<Appointment> getFilteredAppointments(String type) {
    final now = DateTime.now();
    return _appointments.where((appt) {
      final isSameWeek =
          type == 'weekly' &&
          (appt.dateTime.difference(now).inDays <= 7 &&
              appt.dateTime.isAfter(now));
      final isSameMonth =
          type == 'monthly' &&
          (appt.dateTime.month == now.month && appt.dateTime.year == now.year);
      return isSameWeek || isSameMonth;
    }).toList();
  }

  // Adds a new appointment and schedules a notification if it's within 3 hours.
  void addAppointment(Appointment appt) {
    _appointments.add(appt);
    _saveAppointments();
    // Schedule notification if reminder is enabled and appointment is <3 hours away
    final now = DateTime.now();
    final diff = appt.dateTime.difference(now);
    if (appt.reminder && diff.inMinutes > 0 && diff.inMinutes <= 180) {
      app_main.flutterLocalNotificationsPlugin.zonedSchedule(
        appt.id.hashCode,
        'Appointment Reminder',
        'You have an appointment: ${appt.title} at ${appt.dateTime.hour.toString().padLeft(2, '0')}:${appt.dateTime.minute.toString().padLeft(2, '0')}',
        tz.TZDateTime.from(appt.dateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_channel',
            'Appointments',
            channelDescription: 'Notifications for upcoming appointments',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    notifyListeners();
  }

  // Replaces the current list of appointments with a new one and saves it.
  void setAppointments(List<Appointment> appointments) {
    _appointments
      ..clear()
      ..addAll(appointments);
    _saveAppointments();
    notifyListeners();
  }

  // Deletes an appointment by index.
  void removeAppointment(int index) {
    if (index >= 0 && index < _appointments.length) {
      _appointments.removeAt(index);
      _saveAppointments();
      notifyListeners();
    }
  }

  // Updates an existing appointment in the list.
  void updateAppointment(int index, Appointment updatedAppt) {
    if (index >= 0 && index < _appointments.length) {
      _appointments[index] = updatedAppt;
      _saveAppointments();
      notifyListeners();
    }
  }

  // Loads appointments from SharedPreferences.
  Future<void> loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString('appointments');
    if (storedData != null) {
      final List decoded = jsonDecode(storedData);
      _appointments.clear();
      _appointments.addAll(decoded.map((item) => Appointment.fromJson(item)));
      notifyListeners();
    }
  }

  // Saves the appointment list to SharedPreferences as a JSON string.
  void _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data = _appointments
        .map((appt) => appt.toJson())
        .toList();
    await prefs.setString('appointments', jsonEncode(data));
  }
}
