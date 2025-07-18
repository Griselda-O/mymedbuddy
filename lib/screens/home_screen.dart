// Home Screen
// This page serves as the main dashboard and navigation hub for the app.
// It shows the user's health overview, next medication, missed doses, appointments, and provides navigation to all major features.
// State is managed with Provider, and the UI is built with Flutter widgets.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:provider/provider.dart'; // State management
import 'package:intl/intl.dart'; // For formatting dates
import '../providers/medication_provider.dart'; // Medication state provider
import '../providers/appointments_provider.dart'
    as provider; // Appointments state provider
import 'medication_screen.dart'; // Medications page
import 'appointments_screen.dart'; // Appointments page
import 'profile_screen.dart'; // Profile page
import 'health_tips_screen.dart'; // Health tips page
import 'health_logs_screen.dart'; // Health logs page
import '../models/medication.dart' as model; // Medication model
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Notifications
import '../main.dart' as app_main; // Main app (for notification plugin)

// Main HomeScreen widget (stateful for navigation)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// State class for HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  late List<Widget> _pages; // List of pages for navigation
  int _selectedIndex = 0; // Currently selected tab index

  @override
  void initState() {
    super.initState();
    // Initialize the list of pages for the bottom navigation bar
    _pages = [
      DashboardView(), // Main dashboard
      MedicationScreen(), // Medications
      HealthTipsScreen(), // Health tips
      AppointmentsScreen(), // Appointments
      ProfileScreen(), // Profile
      HealthLogsScreen(), // Health logs
    ];
  }

  // Handle tab selection in the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Return the Scaffold directly, using the top-level providers
    return Scaffold(
      body: _selectedIndex < _pages.length
          ? _pages[_selectedIndex] // Show the selected page
          : const Center(child: Text("Invalid tab selected")),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xFF1E88E5), // Selected tab color
        unselectedItemColor: Colors.grey, // Unselected tab color
        backgroundColor: Colors.white, // Nav bar background
        currentIndex: _selectedIndex, // Current tab
        onTap: _onItemTapped, // Handle tab tap
        type: BottomNavigationBarType.fixed, // Fixed tabs
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Logs'),
        ],
      ),
      // Floating action button for test notification (only on Home tab)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                // Send a test notification using flutter_local_notifications
                await app_main.flutterLocalNotificationsPlugin.show(
                  0,
                  'Test Notification',
                  'This is a test notification',
                  const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'test_channel',
                      'Test Channel',
                      channelDescription: 'Channel for test notifications',
                      importance: Importance.max,
                      priority: Priority.high,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.notifications),
              tooltip: 'Send Test Notification',
            )
          : null,
    );
  }
}

// DashboardView widget: shows health overview, medications, appointments, etc.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

// State class for DashboardView
class _DashboardViewState extends State<DashboardView> {
  String selectedView = 'weekly'; // Toggle for weekly/monthly appointments

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context); // Meds
    final appointmentsProvider = Provider.of<provider.AppointmentsProvider>(
      context,
    ); // Appointments
    final now = DateTime.now(); // Current date/time
    final todayStr = now.toIso8601String().split('T')[0]; // Today's date string

    // Filter medications for today (within start/end date)
    final todaysMeds = medicationProvider.medications.where((med) {
      final isInDateRange =
          (med.startDate == null || !now.isBefore(med.startDate!)) &&
          (med.endDate == null || !now.isAfter(med.endDate!));
      return isInDateRange;
    }).toList();

    // Find next upcoming medication (not yet taken today, time is after now)
    model.Medication? nextMed;
    DateTime? soonestTime;
    for (final med in todaysMeds) {
      final takenMap = med.takenHistory[todayStr] ?? {};
      for (final time in med.times) {
        final taken = takenMap[time] ?? false;
        final medDateTime = _parseTime(time, now);
        if (!taken && medDateTime.isAfter(now)) {
          if (soonestTime == null || medDateTime.isBefore(soonestTime)) {
            soonestTime = medDateTime;
            nextMed = med;
          }
        }
      }
    }

    // Missed medications: not taken, time is before now
    final missedMeds = <model.Medication>[];
    for (final med in todaysMeds) {
      final takenMap = med.takenHistory[todayStr] ?? {};
      for (final time in med.times) {
        final medDateTime = _parseTime(time, now);
        final taken = takenMap[time] ?? false;
        if (!taken && medDateTime.isBefore(now)) {
          missedMeds.add(med);
          break;
        }
      }
    }

    // Filter appointments for weekly/monthly view
    List<provider.Appointment> filteredAppointments = selectedView == 'weekly'
        ? appointmentsProvider.getFilteredAppointments('weekly')
        : appointmentsProvider.getFilteredAppointments('monthly');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Page bg
      appBar: AppBar(
        title: Text(
          'Welcome Back 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Health Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatCard(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  value: '3,420',
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.local_drink,
                  label: 'Water',
                  value: '1.5 L',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(
                  icon: Icons.flag,
                  label: 'Weekly Goals',
                  value: '5/7',
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '320 kcal',
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (nextMed != null) ...[
              Text(
                'Next Medication',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              _InfoCard(
                icon: Icons.medical_services,
                title: nextMed.name,
                subtitle: '${nextMed.dosage} at ${nextMed.times.join(", ")}',
              ),
              const SizedBox(height: 20),
            ],
            if (todaysMeds.isNotEmpty) ...[
              Text(
                'Today\'s Medications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: todaysMeds.map((med) {
                  final todayStr = now.toIso8601String().split('T')[0];
                  final takenMap = med.takenHistory[todayStr] ?? {};
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                med.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (med.streak > 0)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${med.streak}d',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...med.times.map((time) {
                            final taken = takenMap[time] ?? false;
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${med.dosage} at $time'),
                              value: taken,
                              onChanged: (val) {
                                Provider.of<MedicationProvider>(
                                  context,
                                  listen: false,
                                ).toggleTaken(med.id, time);
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            if (missedMeds.isNotEmpty) ...[
              const Text(
                'Missed Doses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...missedMeds.map((med) {
                final todayStr = now.toIso8601String().split('T')[0];
                final takenMap = med.takenHistory[todayStr] ?? {};
                final missedTimes = med.times
                    .where(
                      (time) =>
                          !(takenMap[time] ?? false) &&
                          _parseTime(time, now).isBefore(now),
                    )
                    .toList();
                if (missedTimes.isEmpty) return const SizedBox.shrink();
                return Card(
                  color: Colors.red[50],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      med.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${med.dosage} at ${missedTimes.join(', ')} (Missed)',
                    ),
                  ),
                );
              }).toList(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View Appointments',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                ToggleButtons(
                  isSelected: [
                    selectedView == 'weekly',
                    selectedView == 'monthly',
                  ],
                  onPressed: (index) {
                    setState(() {
                      selectedView = index == 0 ? 'weekly' : 'monthly';
                    });
                  },
                  children: const [Text('Weekly'), Text('Monthly')],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (filteredAppointments.isEmpty)
              Text(
                'No upcoming appointments',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Color.fromARGB((0.6 * 255).toInt(), 0, 0, 0),
                ),
              ),
            if (filteredAppointments.isNotEmpty)
              ...filteredAppointments.map((appt) {
                final formattedDate = DateFormat(
                  'yyyy-MM-dd',
                ).format(appt.dateTime);
                final formattedTime = DateFormat(
                  'hh:mm a',
                ).format(appt.dateTime);
                return _InfoCard(
                  icon: Icons.calendar_today,
                  title: appt.doctor,
                  subtitle:
                      '${appt.purpose} on $formattedDate at $formattedTime',
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper to parse a time string (e.g., '08:00') into a DateTime for today
  DateTime _parseTime(String time, DateTime baseDate) {
    // Try to parse time as 'HH:mm' or fallback to 00:00
    try {
      final parts = time.split(":");
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1].split(' ')[0]) ?? 0;
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          minute,
        );
      }
    } catch (_) {}
    return DateTime(baseDate.year, baseDate.month, baseDate.day);
  }
}

// Widget for displaying a stat (e.g., steps, water)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).iconTheme.color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying info (e.g., next medication, appointment)
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
