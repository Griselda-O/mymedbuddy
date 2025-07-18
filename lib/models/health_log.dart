// This model defines the structure of a Health Log entry.
// It includes mood (emoji + text), symptoms, vital signs, and optional notes for a given date.
// Used throughout the app for recording and analyzing daily health data.
// health_log.dart
// Main model class for storing individual health logs
class HealthLog {
  final String id;
  final DateTime date;
  final String mood; // emoji + text
  final List<String> symptoms; // list of emoji+text
  final Map<String, String> vitals; // e.g., {'BP': '120/80', 'HR': '72'}
  final String notes;

  HealthLog({
    required this.id,
    required this.date,
    required this.mood,
    required this.symptoms,
    required this.vitals,
    required this.notes,
  });

  // Converts the HealthLog object into a JSON-compatible map for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mood': mood,
    'symptoms': symptoms,
    'vitals': vitals,
    'notes': notes,
  };

  // Creates a HealthLog object from a JSON map, handling null safety and default values
  factory HealthLog.fromJson(Map<String, dynamic> json) => HealthLog(
    id: json['id'] ?? '',
    date: DateTime.parse(json['date']),
    mood: json['mood'] ?? '',
    symptoms: json['symptoms'] != null
        ? List<String>.from(json['symptoms'])
        : [],
    vitals: json['vitals'] != null
        ? Map<String, String>.from(json['vitals'])
        : {},
    notes: json['notes'] ?? '',
  );
}
