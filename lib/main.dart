// main.dart
// This is the entry point for the MyMedBuddy app. It initializes notifications, permissions, providers, and sets up the app's theme and navigation.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:provider/provider.dart'
    as provider; // Provider for state management
import 'package:mymedbuddy/screens/onboarding_screen.dart'; // Onboarding screen
import 'package:mymedbuddy/screens/home_screen.dart'; // Home screen
import 'package:mymedbuddy/screens/health_tips_screen.dart'; // Health tips screen
import 'package:mymedbuddy/services/shared_prefs_service.dart'; // SharedPrefs for persistence
import 'package:mymedbuddy/providers/medication_provider.dart'; // Medications provider
import 'package:mymedbuddy/providers/appointments_provider.dart'; // Appointments provider
import 'package:mymedbuddy/providers/theme_provider.dart'; // Theme provider
import 'package:mymedbuddy/providers/health_log_provider.dart'; // Health logs provider
import 'package:mymedbuddy/screens/appointments_screen.dart'; // Appointments screen
import 'package:mymedbuddy/screens/profile_screen.dart'; // Profile screen
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Local notifications
import 'dart:io'; // Platform checks
import 'package:android_intent_plus/android_intent.dart'; // Android intent for permissions
import 'package:permission_handler/permission_handler.dart'; // Permission handler
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod for advanced state management

late FlutterLocalNotificationsPlugin
flutterLocalNotificationsPlugin; // Global notifications plugin

// Requests notification permission (Android 13+)
Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  await _promptForExactAlarmPermission(); // Request exact alarm permission if needed

  flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Init plugin

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Android icon

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  ); // Init notifications

  await requestNotificationPermission(); // Request notification permission

  final userData = await SharedPrefsService.getUserData(); // Load user data
  final String initialRoute = (userData == null)
      ? '/onboarding'
      : '/home'; // Decide initial route
  print('Initial route: $initialRoute');
  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute))); // Start app
}

// Prompts for exact alarm permission on Android
Future<void> _promptForExactAlarmPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    }
  }
}

// Main app widget
class MyApp extends StatelessWidget {
  final String initialRoute; // Initial route for navigation
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (_) => MedicationProvider(),
        ), // Medications
        provider.ChangeNotifierProvider(
          create: (_) => AppointmentsProvider(),
        ), // Appointments
        provider.ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // Theme
      ],
      child: provider.Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MyMedBuddy',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              cardColor: Colors.white,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black87),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: const Color(0xFF101518),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1C1F22),
                foregroundColor: Colors.white,
                elevation: 1,
              ),
              cardColor: const Color(0xFF1E2429),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
                bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
                titleLarge: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(color: Colors.white70, fontSize: 18),
                labelLarge: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              switchTheme: const SwitchThemeData(
                thumbColor: WidgetStatePropertyAll(Colors.tealAccent),
                trackColor: WidgetStatePropertyAll(Colors.teal),
              ),
              iconTheme: const IconThemeData(color: Colors.tealAccent),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1C1F22),
                selectedItemColor: Colors.tealAccent,
                unselectedItemColor: Colors.white60,
                showUnselectedLabels: true,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.tealAccent),
                ),
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: initialRoute, // Set initial route
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/appointments': (context) => const AppointmentsScreen(),
              '/healthTips': (context) => const HealthTipsScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
