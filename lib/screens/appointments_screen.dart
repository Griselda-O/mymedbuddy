// Appointments Screen
// This page allows users to add, view, edit, and delete appointments. It supports reminders via notifications and persists data using SharedPreferences. State is managed with Provider.

import 'dart:convert'; // For encoding/decoding appointment data for storage
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:provider/provider.dart'; // State management
import 'package:intl/intl.dart'; // For formatting dates
import '../providers/appointments_provider.dart'; // Appointments state provider
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // For notifications
import 'package:timezone/data/latest.dart'
    as tz; // Timezone support for notifications
import 'package:timezone/timezone.dart'
    as tz; // Timezone support for notifications
import '../../main.dart'; // Main app (for notification plugin)

// Main widget for the Appointments screen
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

// State class for AppointmentsScreen
class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Load appointments from storage after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic visual layout structure
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background
      appBar: AppBar(
        title: const Text('Appointments'), // Page title
        backgroundColor: const Color(0xFF1E88E5), // AppBar color
      ),
      // Consumer listens to AppointmentsProvider for changes
      body: Consumer<AppointmentsProvider>(
        builder: (context, provider, child) {
          // If there are no appointments, show a message
          if (provider.appointments.isEmpty) {
            return const Center(
              child: Text(
                'No appointments scheduled.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }
          // Otherwise, show the list of appointments
          return ListView.builder(
            itemCount: provider.appointments.length, // Number of appointments
            itemBuilder: (context, index) {
              final appt = provider.appointments[index]; // Current appointment
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ), // Card spacing
                elevation: 3, // Card shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12), // Ripple effect
                  onTap: () {
                    // Edit appointment when tapped
                    _showEditAppointmentSheet(context, appt, index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16), // Card padding
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF4F7FA), // Card background
                    ),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Calendar icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE3F2FD),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ), // Space between icon and text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Appointment title
                                  Text(
                                    appt.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Appointment date/time
                                  Text(
                                    DateFormat(
                                      'EEE, MMM d • hh:mm a',
                                    ).format(appt.dateTime),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Doctor name (if provided)
                                  if (appt.doctor.isNotEmpty)
                                    Text(
                                      'With Dr.  ${appt.doctor}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  // Purpose (if provided)
                                  if (appt.purpose.isNotEmpty)
                                    Text(
                                      'Purpose: ${appt.purpose}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Delete button
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => provider.removeAppointment(
                                    index,
                                  ), // Remove appointment
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Edit button (top right)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showEditAppointmentSheet(
                                context,
                                appt,
                                index,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // Floating action button to add a new appointment
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () => _showAddAppointmentSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Show bottom sheet to add a new appointment
  void _showAddAppointmentSheet(BuildContext context) {
    final titleController =
        TextEditingController(); // Controller for title input
    String doctor = '';
    String purpose = '';
    String location = '';
    String notes = '';
    bool reminder = false;
    DateTime? selectedDateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow sheet to resize for keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(
            context,
          ).viewInsets.bottom, // Avoid keyboard overlap
          top: 20,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Appointment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Title input
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Appointment Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Doctor input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Doctor',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => doctor = val,
                  ),
                  const SizedBox(height: 12),
                  // Purpose input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => purpose = val,
                  ),
                  const SizedBox(height: 12),
                  // Location input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => location = val,
                  ),
                  const SizedBox(height: 12),
                  // Notes input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (val) => notes = val,
                  ),
                  const SizedBox(height: 12),
                  // Reminder toggle
                  SwitchListTile(
                    title: const Text('Set Reminder'),
                    value: reminder,
                    onChanged: (val) => setModalState(() => reminder = val),
                  ),
                  const SizedBox(height: 12),
                  // Date/time picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 2),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (!context.mounted) return;
                        if (time != null) {
                          setModalState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      selectedDateTime == null
                          ? 'Pick Date & Time'
                          : DateFormat(
                              'EEE, MMM d • hh:mm a',
                            ).format(selectedDateTime!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Privacy info
                  Row(
                    children: const [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Appointments are stored privately on your device only.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Save button
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty &&
                          selectedDateTime != null) {
                        final newAppt = Appointment(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          dateTime: selectedDateTime!,
                          doctor: doctor,
                          purpose: purpose,
                          location: location,
                          notes: notes,
                          reminder: reminder,
                        );
                        Provider.of<AppointmentsProvider>(
                          context,
                          listen: false,
                        ).addAppointment(newAppt); // Add to provider
                        Navigator.pop(context); // Close sheet
                        _saveAppointments(); // Persist data
                        _showConfirmationDialog(context); // Show confirmation
                        // --- Notification logic ---
                        if (reminder) {
                          final now = DateTime.now();
                          final diff = selectedDateTime!.difference(now);
                          if (diff.inHours < 12 && diff.isNegative == false) {
                            tz.initializeTimeZones();
                            await flutterLocalNotificationsPlugin.zonedSchedule(
                              newAppt.id.hashCode,
                              'Upcoming Appointment',
                              'You have an appointment: ${newAppt.title} at ${DateFormat('hh:mm a').format(newAppt.dateTime)}',
                              tz.TZDateTime.from(newAppt.dateTime, tz.local),
                              const NotificationDetails(
                                android: AndroidNotificationDetails(
                                  'appointment_channel',
                                  'Appointments',
                                  channelDescription:
                                      'Notifications for upcoming appointments',
                                  importance: Importance.max,
                                  priority: Priority.high,
                                ),
                              ),
                              androidAllowWhileIdle: true,
                              uiLocalNotificationDateInterpretation:
                                  UILocalNotificationDateInterpretation
                                      .absoluteTime,
                            );
                          }
                        }
                        // --- End notification logic ---
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                    child: const Text('Save Appointment'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Show bottom sheet to edit an existing appointment
  void _showEditAppointmentSheet(
    BuildContext context,
    Appointment appt,
    int index,
  ) {
    final titleController = TextEditingController(
      text: appt.title,
    ); // Pre-fill title
    final doctorController = TextEditingController(
      text: appt.doctor,
    ); // Pre-fill doctor
    final purposeController = TextEditingController(
      text: appt.purpose,
    ); // Pre-fill purpose
    final locationController = TextEditingController(
      text: appt.location,
    ); // Pre-fill location
    final notesController = TextEditingController(
      text: appt.notes,
    ); // Pre-fill notes
    bool reminder = appt.reminder;
    DateTime selectedDateTime = appt.dateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Appointment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Title input
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Appointment Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Doctor input
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Purpose input
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location input
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes input
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Reminder toggle
                  SwitchListTile(
                    title: const Text('Set Reminder'),
                    value: reminder,
                    onChanged: (val) => setModalState(() => reminder = val),
                  ),
                  const SizedBox(height: 12),
                  // Date/time picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: now,
                        lastDate: DateTime(now.year + 2),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (!context.mounted) return;
                        if (time != null) {
                          setModalState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      DateFormat(
                        'EEE, MMM d • hh:mm a',
                      ).format(selectedDateTime),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Update button
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        final updated = Appointment(
                          id: appt.id,
                          title: titleController.text,
                          dateTime: selectedDateTime,
                          doctor: doctorController.text,
                          purpose: purposeController.text,
                          location: locationController.text,
                          notes: notesController.text,
                          reminder: reminder,
                        );
                        final provider = Provider.of<AppointmentsProvider>(
                          context,
                          listen: false,
                        );
                        provider.updateAppointment(
                          index,
                          updated,
                        ); // Update in provider
                        _saveAppointments(); // Persist data
                        Navigator.pop(context); // Close sheet
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                    child: const Text('Update Appointment'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Show confirmation dialog after saving
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Color(0xFF1E88E5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Saved Securely',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your appointment has been saved and is private to your device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save appointments to SharedPreferences
  void _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = Provider.of<AppointmentsProvider>(context, listen: false);
    final encoded = jsonEncode(
      provider.appointments.map((appt) => appt.toJson()).toList(),
    );
    await prefs.setString('appointments', encoded);
  }

  // Load appointments from SharedPreferences
  void _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('appointments');
    if (!mounted) return;
    if (data != null) {
      final decoded = jsonDecode(data) as List<dynamic>;
      final loadedAppointments = decoded
          .map((json) => Appointment.fromJson(json))
          .toList();
      final provider = Provider.of<AppointmentsProvider>(
        context,
        listen: false,
      );
      provider.setAppointments(loadedAppointments);
    }
  }
}
