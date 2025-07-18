// This file defines the Appointment model, which represents a user's medical appointment.
// It includes details such as title, datetime, doctor, purpose, location, notes, and reminder status.
// The model also provides serialization methods for saving and loading appointments.

import 'package:intl/intl.dart'; // For formatting date and time

// Class representing a medical appointment
class Appointment {
  final String id; // Unique identifier for the appointment
  final String title; //
  final DateTime dateTime; 
  final String doctor; 
  final String purpose; 
  final String? location; 
  final String? notes; 
  final bool reminder; 

  // Constructor with required and optional fields
  Appointment({
    required this.id, 
    required this.title,
    required this.dateTime, 
    required this.doctor, 
    required this.purpose, 
    this.location, // Optional: location
    this.notes, // Optional: notes
    this.reminder = true, // Default value for reminder is true
  });

  // Getter to format the date for display
  String get appointmentDate => DateFormat('yyyy-MM-dd').format(dateTime);

  // Getter to format the time for display
  String get appointmentTime => DateFormat('hh:mm a').format(dateTime);

  // Converts the Appointment object to a JSON map
  Map<String, dynamic> toJson() => {
        'id': id, // Appointment ID
        'title': title, // Appointment title
        'dateTime': dateTime.toIso8601String(), // ISO string for date/time
        'doctor': doctor, // Doctor name
        'purpose': purpose, // Appointment purpose
        'location': location, // Location (nullable)
        'notes': notes, // Notes (nullable)
        'reminder': reminder, // Reminder status
      };

  // Creates an Appointment object from a JSON map
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'], // Parse ID
        title: json['title'], // Parse title
        dateTime: DateTime.parse(json['dateTime']), // Parse ISO date/time
        doctor: json['doctor'], // Parse doctor
        purpose: json['purpose'], // Parse purpose
        location: json['location'], // Parse location (nullable)
        notes: json['notes'], // Parse notes (nullable)
        reminder: json['reminder'] ?? true, // Default to true if reminder field is missing
      );
}
