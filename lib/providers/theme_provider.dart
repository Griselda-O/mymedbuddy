// Theme Provider
// This provider manages the app's theme (dark mode or light mode).
// It uses ChangeNotifier for state management and SharedPreferences for persistence.
// It exposes methods and properties to get/set the theme and notifies listeners on changes.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage

// ThemeProvider manages the app's theme state and notifies listeners when it changes.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false; // Private variable to track dark mode

  // Public getter for dark mode status
  bool get isDarkMode => _isDarkMode;

  // Getter for the light theme configuration
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light, // Light mode
    primarySwatch: Colors.teal, // Primary color
    scaffoldBackgroundColor: Colors.grey[100], // Background color
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.teal, // AppBar color
      foregroundColor: Colors.white, // AppBar text/icon color
    ),
    cardColor: Colors.white, // Card background
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black), // Text color
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.teal), // Switch thumb
      trackColor: WidgetStateProperty.all(Colors.tealAccent), // Switch track
    ),
  );

  // Getter for the dark theme configuration
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark, // Dark mode
    primarySwatch: Colors.teal, // Primary color
    scaffoldBackgroundColor: Colors.grey[900], // Background color
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87, // AppBar color
      foregroundColor: Colors.white, // AppBar text/icon color
    ),
    cardColor: Colors.grey[800], // Card background
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white), // Text color
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.tealAccent), // Switch thumb
      trackColor: WidgetStateProperty.all(Colors.teal), // Switch track
    ),
  );

  // Constructor: initializes the theme from saved preferences
  ThemeProvider() {
    _initialize();
  }

  // Loads the saved theme preference and notifies listeners
  void _initialize() async {
    await _loadThemePreference();
    notifyListeners(); // Notify only after loading the saved preference
  }

  // Toggles between dark and light mode, saves preference, and notifies listeners
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  // Loads the theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
  }

  // Saves the current theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
}
