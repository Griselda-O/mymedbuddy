// Profile Screen
// This page displays and allows editing of the user's profile information, avatar, health stats, and preferences (like dark mode).
// It uses SharedPreferences for persistence and Provider for theme management.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage
import 'package:provider/provider.dart'; // State management
import '../providers/theme_provider.dart'; // Theme provider for dark mode

// Main widget for the Profile screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// State class for ProfileScreen
class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Your Name'; // User's name
  String userEmail = 'email@example.com'; // User's email
  bool isDarkMode = false; // Dark mode status
  double? userWeight; // User's weight
  double? userHeight; // User's height

  @override
  void initState() {
    super.initState();
    loadUserData(); // Load user data on init
  }

  // Loads user data from SharedPreferences
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'Your Name';
      userEmail = prefs.getString('email') ?? 'email@example.com';
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      userWeight = prefs.getDouble('userWeight');
      userHeight = prefs.getDouble('userHeight');
      // Add this if you save avatar later
      // userAvatarUrl = prefs.getString('userAvatarUrl') ?? '';
    });
  }

  // Toggles dark mode and saves preference
  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      isDarkMode = value;
    });
    // Notify the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  // Allows user to edit avatar image URL
  Future<void> editAvatar() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Avatar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Avatar Image URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userAvatarUrl', controller.text);
              if (!mounted) return;
              setState(() {});
              Navigator.pop(context);
              loadUserData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double? bmiValue;
    String bmiCategory = '';
    // Calculate BMI if weight and height are available
    if (userWeight != null &&
        userHeight != null &&
        userHeight! > 0 &&
        userWeight! > 0) {
      bmiValue = userWeight! / ((userHeight! / 100) * (userHeight! / 100));
      bmiCategory = _bmiCategory(userWeight!, userHeight!);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'), // Page title
        backgroundColor: const Color(0xFF1E88E5), // AppBar color
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Page padding
        children: [
          // Avatar and edit button
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final prefs = snapshot.data!;
                return GestureDetector(
                  onTap: editAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          prefs.getString('userAvatarUrl') ??
                              'https://via.placeholder.com/150',
                        ),
                      ),
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                );
              } else {
                return const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150',
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(userEmail, style: TextStyle(color: Colors.grey[600])),
          ),
          if (bmiValue != null)
            Column(
              children: [
                Center(
                  child: Text(
                    'BMI: ${bmiValue.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    bmiCategory,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Text(
            'Your Health Goals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.grey[300],
            color: Colors.green,
            minHeight: 12,
          ),
          const SizedBox(height: 6),
          const Center(child: Text('Weekly Goal: 7/10 steps completed')),
          const SizedBox(height: 16),
          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(Icons.directions_walk, color: Colors.blue),
                  const SizedBox(height: 4),
                  const Text('Steps\n5200', textAlign: TextAlign.center),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.local_drink, color: Colors.teal),
                  const SizedBox(height: 4),
                  const Text('Water\n1.5L', textAlign: TextAlign.center),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.deepOrange),
                  const SizedBox(height: 4),
                  const Text('Calories\n180 kcal', textAlign: TextAlign.center),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Settings tile
          Container(
            color: Colors.grey[100],
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const Divider(height: 1),
          // Dark mode toggle
          Container(
            color: Colors.grey[100],
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              leading: const Icon(Icons.brightness_6),
              title: const Text('Dark Mode'),
              trailing: Switch(value: isDarkMode, onChanged: toggleDarkMode),
            ),
          ),
          const Divider(height: 1),
          // Edit profile tile
          Container(
            color: Colors.grey[100],
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final nameController = TextEditingController(text: userName);
                final emailController = TextEditingController(text: userEmail);
                double? selectedWeight = userWeight;
                double? selectedHeight = userHeight;

                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setDialogState) {
                        return AlertDialog(
                          title: const Text('Edit Profile'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                ),
                                TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                DropdownButtonFormField<double>(
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                  ),
                                  value:
                                      (selectedWeight ?? 0) >= 30 &&
                                          (selectedWeight ?? 0) <= 200
                                      ? selectedWeight
                                      : null,
                                  items:
                                      List.generate(
                                        171,
                                        (index) => 30 + index,
                                      ).map((value) {
                                        return DropdownMenuItem<double>(
                                          value: value.toDouble(),
                                          child: Text(value.toString()),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedWeight = value;
                                    });
                                  },
                                ),
                                DropdownButtonFormField<double>(
                                  decoration: const InputDecoration(
                                    labelText: 'Height (cm)',
                                  ),
                                  value:
                                      (selectedHeight ?? 0) >= 100 &&
                                          (selectedHeight ?? 0) <= 250
                                      ? selectedHeight
                                      : null,
                                  items:
                                      List.generate(
                                        151,
                                        (index) => 100 + index,
                                      ).map((value) {
                                        return DropdownMenuItem<double>(
                                          value: value.toDouble(),
                                          child: Text(value.toString()),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedHeight = value;
                                    });
                                  },
                                ),
                                if (selectedWeight != null &&
                                    selectedHeight != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Text(
                                      'BMI: ${(selectedWeight! / ((selectedHeight! / 100) * (selectedHeight! / 100))).toStringAsFixed(1)} (${_bmiCategory(selectedWeight!, selectedHeight!)})',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (selectedWeight == null ||
                                    selectedHeight == null ||
                                    nameController.text.isEmpty ||
                                    emailController.text.isEmpty) {
                                  // Optionally show error or just return
                                  return;
                                }
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'name',
                                  nameController.text,
                                );
                                await prefs.setString(
                                  'email',
                                  emailController.text,
                                );
                                await prefs.setDouble(
                                  'userWeight',
                                  selectedWeight!,
                                );
                                await prefs.setDouble(
                                  'userHeight',
                                  selectedHeight!,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                loadUserData();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Log out tile
          Container(
            color: Colors.grey[100],
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/onboarding');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper to categorize BMI value
  String _bmiCategory(double weight, double height) {
    final bmi = weight / ((height / 100) * (height / 100));
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 24.9) return 'Normal weight';
    if (bmi < 29.9) return 'Overweight';
    return 'Obesity';
  }
}
