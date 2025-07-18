// Onboarding Screen
// This page collects user details (name, age, condition, reminder preference) on first launch.
// It saves the data using SharedPreferences and skips onboarding on future launches.
// If reminders are enabled, it requests the necessary Android permission.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:mymedbuddy/services/shared_prefs_service.dart'; // For saving/loading user data
import 'home_screen.dart'; // Home screen to navigate after onboarding
import 'package:uuid/uuid.dart'; // For generating unique IDs (if needed)
import 'package:android_intent_plus/android_intent.dart'; // For Android intent to request alarm permission
import 'dart:io'; // For platform checks

// Main widget for the onboarding screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// State class for OnboardingScreen
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for the form
  String name = ''; // User's name
  int age = 0; // User's age
  String condition = ''; // User's health condition
  bool reminder = false; // Whether reminders are enabled

  // Handles form submission: validates, saves data, requests permission if needed, navigates to Home
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await SharedPrefsService.saveUserData(
        name,
        age,
        condition,
        reminder,
      ); // Save user data
      if (reminder && Platform.isAndroid) {
        final alreadyRequested =
            await SharedPrefsService.getReminderPermissionRequested();
        if (!alreadyRequested) {
          final intent = AndroidIntent(
            action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
          );
          await intent.launch(); // Request alarm permission
          await SharedPrefsService.setReminderPermissionRequested(true);
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ), // Go to Home
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Page background
      appBar: AppBar(
        title: const Text('Welcome to MyMedBuddy'), // App title
        backgroundColor: Colors.teal, // AppBar color
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24), // Page padding
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Card corners
              ),
              elevation: 5, // Card shadow
              child: Padding(
                padding: const EdgeInsets.all(24), // Card padding
                child: Form(
                  key: _formKey, // Form key
                  child: Column(
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => name = val ?? '',
                        validator: (val) =>
                            val!.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      // Age input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => age = int.tryParse(val ?? '0') ?? 0,
                        validator: (val) =>
                            val!.isEmpty ? 'Enter your age' : null,
                      ),
                      const SizedBox(height: 16),
                      // Health condition input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Health Condition',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => condition = val ?? '',
                        validator: (val) =>
                            val!.isEmpty ? 'Enter your condition' : null,
                      ),
                      const SizedBox(height: 16),
                      // Reminder toggle
                      SwitchListTile(
                        title: const Text('Enable Medication Reminders'),
                        value: reminder,
                        onChanged: (val) {
                          setState(() => reminder = val);
                        },
                        activeColor: Colors.teal,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
