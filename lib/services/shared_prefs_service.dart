// Shared Preferences Service
// This service handles all persistent storage of user data, preferences, and multi-user support using SharedPreferences.
// It provides robust methods for saving, loading, cleaning, and debugging user data, including error handling and data recovery.

import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart'; // Persistent storage

class SharedPrefsService {
  // Keys for storing user data
  static const _keyName = 'name';
  static const _keyAge = 'age';
  static const _keyCondition = 'condition';
  static const _keyReminder = 'reminder';
  static const _keyUsers = 'users_list';
  static const _keyCurrentUser = 'current_user_id';
  static const _keyReminderPermissionRequested =
      'reminder_permission_requested';

  // Save user data (single user)
  static Future<void> saveUserData(
    String name,
    int age,
    String condition,
    bool reminder,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setInt(_keyAge, age);
    await prefs.setString(_keyCondition, condition);
    await prefs.setBool(_keyReminder, reminder);
  }

  // Load user data (single user)
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyName)) return null;

    try {
      // Get raw values safely with null checks
      final nameValue = prefs.getString(_keyName) ?? 'User';
      final ageValue = prefs.containsKey(_keyAge) ? prefs.get(_keyAge) : null;
      final conditionValue = prefs.containsKey(_keyCondition)
          ? prefs.get(_keyCondition)
          : null;
      final reminderValue = prefs.containsKey(_keyReminder)
          ? prefs.get(_keyReminder)
          : null;
      return {
        'name': nameValue is String ? nameValue : nameValue?.toString(),
        'age': ageValue is int
            ? ageValue
            : (ageValue is String ? int.tryParse(ageValue) : null),
        'condition': conditionValue is String
            ? conditionValue
            : conditionValue?.toString(),
        'reminder': reminderValue is bool
            ? reminderValue
            : (reminderValue is String
                  ? reminderValue.toLowerCase() == 'true'
                  : null),
      };
    } catch (e) {
      debugPrint("Error reading user data: $e");
      // If there's an error, try to fix corrupted data and return null
      await fixCorruptedData();
      return null;
    }
  }

  // Debug method to print all stored user data
  static Future<void> debugStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("=== SharedPreferences Debug ===");
    debugPrint(
      "Name:  {prefs.get(_keyName)} ( {prefs.get(_keyName).runtimeType})",
    );
    debugPrint(
      "Age:  {prefs.get(_keyAge)} ( {prefs.get(_keyAge).runtimeType})",
    );
    debugPrint(
      "Condition:  {prefs.get(_keyCondition)} ( {prefs.get(_keyCondition).runtimeType})",
    );
    debugPrint(
      "Reminder:  {prefs.get(_keyReminder)} ( {prefs.get(_keyReminder).runtimeType})",
    );
    debugPrint("===============================");
  }

  // Fixes corrupted data (e.g., age/reminder stored as String)
  static Future<void> fixCorruptedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check and fix age if it's stored as String
    final ageValue = prefs.get(_keyAge);
    if (ageValue is String) {
      debugPrint("Fixing corrupted age data...");
      final intAge = int.tryParse(ageValue);
      if (intAge != null) {
        await prefs.setInt(_keyAge, intAge);
        debugPrint("Age fixed: $intAge");
      } else {
        await prefs.remove(_keyAge);
        debugPrint("Invalid age data removed");
      }
    }

    // Check and fix reminder if it's stored as String
    final reminderValue = prefs.get(_keyReminder);
    if (reminderValue is String) {
      debugPrint("Fixing corrupted reminder data...");
      final boolReminder = reminderValue.toLowerCase() == 'true';
      await prefs.setBool(_keyReminder, boolReminder);
      debugPrint("Reminder fixed: $boolReminder");
    }
  }

  // Bulletproof method to get user data with comprehensive error handling
  static Future<Map<String, dynamic>?> getBulletproofUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if essential data exists
    if (!prefs.containsKey(_keyName)) return null;

    try {
      // Get values with proper type checking
      final name = prefs.getString(_keyName) ?? 'User';
      final age = prefs.getInt(_keyAge);
      final condition = prefs.getString(_keyCondition) ?? 'Healthy';
      final reminder = prefs.getBool(_keyReminder);

      return {
        'name': name,
        'age': age,
        'condition': condition,
        'reminder': reminder,
      };
    } catch (e) {
      debugPrint("Error getting user data: $e");

      // Try to recover each field individually
      final Map<String, dynamic> recoveredData = {};

      // Recover name
      try {
        final nameValue = prefs.get(_keyName) ?? 'User';
        if (nameValue is String) {
          recoveredData['name'] = nameValue;
        } else {
          recoveredData['name'] = nameValue?.toString();
        }
      } catch (e) {
        debugPrint("Could not recover name: $e");
        recoveredData['name'] = null;
      }

      // Recover age
      try {
        final ageValue = prefs.get(_keyAge);
        if (ageValue is int) {
          recoveredData['age'] = ageValue;
        } else if (ageValue is String) {
          recoveredData['age'] = int.tryParse(ageValue);
        } else {
          recoveredData['age'] = null;
        }
      } catch (e) {
        debugPrint("Could not recover age: $e");
        recoveredData['age'] = null;
      }

      // Recover condition
      try {
        final conditionValue = prefs.get(_keyCondition) ?? 'Healthy';
        if (conditionValue is String) {
          recoveredData['condition'] = conditionValue;
        } else {
          recoveredData['condition'] = conditionValue?.toString();
        }
      } catch (e) {
        debugPrint("Could not recover condition: $e");
        recoveredData['condition'] = null;
      }

      // Recover reminder
      try {
        final reminderValue = prefs.get(_keyReminder);
        if (reminderValue is bool) {
          recoveredData['reminder'] = reminderValue;
        } else if (reminderValue is String) {
          recoveredData['reminder'] = reminderValue.toLowerCase() == 'true';
        } else {
          recoveredData['reminder'] = null;
        }
      } catch (e) {
        debugPrint("Could not recover reminder: $e");
        recoveredData['reminder'] = null;
      }

      return recoveredData;
    }
  }

  // Safe getter with null safety and retry after fix
  static Future<Map<String, dynamic>?> getSafeUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if essential data exists
    if (!prefs.containsKey(_keyName)) return null;

    try {
      return {
        'name': prefs.getString(_keyName),
        'age': prefs.getInt(_keyAge),
        'condition': prefs.getString(_keyCondition),
        'reminder': prefs.getBool(_keyReminder),
      };
    } catch (e) {
      debugPrint("Error getting user data: $e");
      debugPrint("Attempting to fix corrupted data...");
      await fixCorruptedData();

      // Try again after fixing
      try {
        return {
          'name': prefs.getString(_keyName),
          'age': prefs.getInt(_keyAge),
          'condition': prefs.getString(_keyCondition),
          'reminder': prefs.getBool(_keyReminder),
        };
      } catch (e2) {
        debugPrint("Still failed after fix attempt: $e2");
        return null;
      }
    }
  }

  // Manual data cleanup method
  static Future<void> cleanupAndReset() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("Cleaning up SharedPreferences...");

    // Remove all user data keys
    await prefs.remove(_keyName);
    await prefs.remove(_keyAge);
    await prefs.remove(_keyCondition);
    await prefs.remove(_keyReminder);

    debugPrint("All user data cleared successfully");
  }

  // Remove user data keys
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyAge);
    await prefs.remove(_keyCondition);
    await prefs.remove(_keyReminder);
  }

  // Check if user data exists
  static Future<bool> hasUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyName) &&
        prefs.containsKey(_keyAge) &&
        prefs.containsKey(_keyCondition) &&
        prefs.containsKey(_keyReminder);
  }

  // Safe getters for each field
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return prefs.getString(_keyName);
    } catch (e) {
      debugPrint("Error getting name: $e");
      return null;
    }
  }

  static Future<int?> getAge() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final ageValue = prefs.get(_keyAge);
      if (ageValue is int) return ageValue;
      if (ageValue is String) return int.tryParse(ageValue);
      return null;
    } catch (e) {
      debugPrint("Error getting age: $e");
      return null;
    }
  }

  static Future<String?> getCondition() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return prefs.getString(_keyCondition);
    } catch (e) {
      debugPrint("Error getting condition: $e");
      return null;
    }
  }

  static Future<bool?> getReminder() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final reminderValue = prefs.get(_keyReminder);
      if (reminderValue is bool) return reminderValue;
      if (reminderValue is String) return reminderValue.toLowerCase() == 'true';
      return null;
    } catch (e) {
      debugPrint("Error getting reminder: $e");
      return null;
    }
  }

  // Reminder permission flag (Android)
  static Future<bool> getReminderPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderPermissionRequested) ?? false;
  }

  static Future<void> setReminderPermissionRequested(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderPermissionRequested, value);
  }

  // Multi-user support: save a new user profile
  static Future<void> saveUserProfile(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> users = prefs.getStringList(_keyUsers) ?? [];
    users.add(user['id']);
    await prefs.setStringList(_keyUsers, users);
    await prefs.setString('user_${user['id']}', user.toString());
  }

  // Get all users (returns list of user maps)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> users = prefs.getStringList(_keyUsers) ?? [];
    List<Map<String, dynamic>> userList = [];
    for (final id in users) {
      final userStr = prefs.getString('user_$id');
      if (userStr != null) {
        final userMap = _parseUserString(userStr);
        if (userMap != null) userList.add(userMap);
      }
    }
    return userList;
  }

  // Set current user
  static Future<void> setCurrentUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, userId);
  }

  // Get current user id
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUser);
  }

  // Helper to parse user string to map
  static Map<String, dynamic>? _parseUserString(String userStr) {
    // Very basic parser for Map<String, dynamic> from toString()
    // Expects format: {id: ..., name: ..., email: ...}
    final reg = RegExp(r'{(.*)}');
    final match = reg.firstMatch(userStr);
    if (match != null) {
      final pairs = match.group(1)!.split(', ');
      final map = <String, dynamic>{};
      for (final pair in pairs) {
        final kv = pair.split(': ');
        if (kv.length == 2) {
          map[kv[0]] = kv[1];
        }
      }
      return map;
    }
    return null;
  }
}
