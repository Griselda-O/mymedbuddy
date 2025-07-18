// This file defines the Medication model used in the MyMedBuddy app.
// It includes details such as medication name, dosage, times per day,
// user preferences, and tracking fields for history and streaks.

import 'dart:io';

// Represents a user's medication entry with scheduling, tracking, and optional metadata
class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final String category;
  final String imageUrl;
  final File? customImage;
  final String? takenWhen;
  final String? takenWith;
  final bool taken;
  final DateTime? startDate;
  final DateTime? endDate;
  // Tracks each date and the specific times the medication was marked as taken
  final Map<String, Map<String, bool>> takenHistory;
  // Counts how many consecutive days the user has fully taken this medication
  final int streak;
  final DateTime? lastTakenDate;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.category,
    required this.imageUrl,
    this.customImage,
    this.takenWhen,
    this.takenWith,
    this.taken = false,
    this.startDate,
    this.endDate,
    this.takenHistory = const {},
    this.streak = 0,
    this.lastTakenDate,
  });

  // Converts Medication object to a JSON map for storage or serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'times': times,
    'category': category,
    'imageUrl': imageUrl,
    'customImagePath': customImage?.path,
    'takenWhen': takenWhen,
    'takenWith': takenWith,
    'taken': taken,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'takenHistory': takenHistory,
    'streak': streak,
    'lastTakenDate': lastTakenDate?.toIso8601String(),
  };

  // Creates a Medication object from a JSON map, used for restoring saved data
  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    dosage: (json['dosage'] ?? '').toString(),
    times: json['times'] != null
        ? List<String>.from(json['times'])
        : json['time'] != null
        ? [(json['time'] ?? '').toString()]
        : [],
    category: (json['category'] ?? '').toString(),
    imageUrl: (json['imageUrl'] ?? '').toString(),
    customImage:
        (json['customImagePath'] != null &&
            json['customImagePath'].toString().isNotEmpty &&
            File(json['customImagePath'].toString()).existsSync())
        ? File(json['customImagePath'].toString())
        : null,
    takenWhen: json['takenWhen'],
    takenWith: json['takenWith'],
    taken: json['taken'] ?? false,
    startDate: json['startDate'] != null
        ? DateTime.tryParse(json['startDate'])
        : null,
    endDate: json['endDate'] != null
        ? DateTime.tryParse(json['endDate'])
        : null,
    takenHistory: (json['takenHistory'] != null)
        ? (json['takenHistory'] as Map).map(
            (k, v) => MapEntry(k.toString(), Map<String, bool>.from(v)),
          )
        : {},
    streak: json['streak'] ?? 0,
    lastTakenDate: json['lastTakenDate'] != null
        ? DateTime.tryParse(json['lastTakenDate'])
        : null,
  );

  // Returns a copy of the Medication object with optional updated fields
  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    List<String>? times,
    String? category,
    String? imageUrl,
    File? customImage,
    String? takenWhen,
    String? takenWith,
    bool? taken,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, Map<String, bool>>? takenHistory,
    int? streak,
    DateTime? lastTakenDate,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      customImage: customImage ?? this.customImage,
      takenWhen: takenWhen ?? this.takenWhen,
      takenWith: takenWith ?? this.takenWith,
      taken: taken ?? this.taken,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      takenHistory: takenHistory ?? this.takenHistory,
      streak: streak ?? this.streak,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
    );
  }
}
