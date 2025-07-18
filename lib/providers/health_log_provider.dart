// Health Log Provider
// This provider manages the list of health logs in the MyMedBuddy app.
// It uses Riverpod's StateNotifier for state management and SharedPreferences for local persistence.
// It supports loading, saving, adding, updating, and removing health log entries.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod for state management
import '../models/health_log.dart'; // HealthLog model
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage
import 'dart:convert'; // For encoding/decoding logs

// A StateNotifier that holds a list of HealthLog entries.
// It allows for loading from and saving to SharedPreferences,
// as well as modifying the list of logs.
class HealthLogNotifier extends StateNotifier<List<HealthLog>> {
  HealthLogNotifier() : super([]); // Initialize with empty list

  // Loads health logs from SharedPreferences and updates the state.
  Future<void> loadLogs() async {
    final prefs =
        await SharedPreferences.getInstance(); // Get SharedPreferences instance
    final logsJson =
        prefs.getStringList('health_logs') ??
        []; // Get saved logs or empty list
    state = logsJson
        .map((e) => HealthLog.fromJson(jsonDecode(e)))
        .toList(); // Decode and update state
  }

  // Serializes and saves the current state of logs to SharedPreferences.
  Future<void> saveLogs() async {
    final prefs =
        await SharedPreferences.getInstance(); // Get SharedPreferences instance
    final logsJson = state
        .map((e) => jsonEncode(e.toJson()))
        .toList(); // Encode logs to JSON
    await prefs.setStringList(
      'health_logs',
      logsJson,
    ); // Save to SharedPreferences
  }

  // Adds a new HealthLog to the state and persists the change.
  void addLog(HealthLog log) {
    state = [...state, log]; // Add new log to list
    saveLogs(); // Persist change
  }

  // Updates an existing HealthLog in the state by matching its ID.
  void updateLog(HealthLog updatedLog) {
    state = [
      for (final log in state)
        if (log.id == updatedLog.id)
          updatedLog
        else
          log, // Replace matching log
    ];
    saveLogs(); // Persist change
  }

  // Removes a HealthLog from the state by its ID and saves the updated state.
  void removeLog(String id) {
    state = state.where((log) => log.id != id).toList(); // Remove log by ID
    saveLogs(); // Persist change
  }
}

// A global provider for accessing the HealthLogNotifier from the UI or other logic.
final healthLogNotifierProvider =
    StateNotifierProvider<HealthLogNotifier, List<HealthLog>>(
      (ref) => HealthLogNotifier(), // Create notifier instance
    );
