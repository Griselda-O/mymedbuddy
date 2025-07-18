// User Selection Screen
// This page allows the user to select from existing user profiles or add a new user.
// It loads users from SharedPreferences and navigates to onboarding or home as needed.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import '../services/shared_prefs_service.dart'; // For user data persistence
import 'onboarding_screen.dart'; // Onboarding for new users
import 'home_screen.dart'; // Home screen after user selection

// Main widget for the user selection screen
class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

// State class for UserSelectionScreen
class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<Map<String, dynamic>> users = []; // List of user profiles
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Load users on init
  }

  // Loads users from SharedPreferences
  Future<void> _loadUsers() async {
    final loadedUsers = await SharedPrefsService.getAllUsers();
    setState(() {
      users = loadedUsers;
      isLoading = false;
    });
  }

  // Handles user selection and navigates to Home
  void _selectUser(String userId) async {
    await SharedPrefsService.setCurrentUser(userId);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Navigates to onboarding to add a new user
  void _addNewUser() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    ).then((_) => _loadUsers()); // Reload users after onboarding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'), // Page title
        backgroundColor: Colors.teal, // AppBar color
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show loading spinner
          : Padding(
              padding: const EdgeInsets.all(24), // Page padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Who is using MyMedBuddy?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (users.isEmpty)
                    const Text(
                      'No users found. Add a new user to get started.',
                    ),
                  // List of user cards
                  ...users.map(
                    (user) => Card(
                      child: ListTile(
                        title: Text(user['name'] ?? ''),
                        subtitle: Text(user['email'] ?? ''),
                        onTap: () => _selectUser(user['id']), // Select user
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Add new user button
                  ElevatedButton.icon(
                    onPressed: _addNewUser,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
