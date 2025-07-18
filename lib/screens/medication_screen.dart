import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart' as provider;
import '../models/medication.dart' as model;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../main.dart';

// Medication Screen: Add/view medications, mark doses, see streaks
// Uses Provider for medication state, schedules notifications
class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final TextEditingController takenWithController = TextEditingController();
  String? takenWhen;

  int timesPerDay = 1;
  List<String> selectedTimes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeSlots = List.generate(24, (i) {
      final period = i < 5 || i >= 21
          ? 'Night'
          : i < 12
          ? 'Morning'
          : i < 17
          ? 'Afternoon'
          : 'Evening';
      final timeLabel = TimeOfDay(hour: i, minute: 0).format(context);
      return '$timeLabel - $period';
    });
  }

  final List<String> _dosages = [
    '1 tablet',
    '2 tablets',
    '5 ml',
    '10 ml',
    'Half tablet',
    'Other',
  ];
  late List<String> _timeSlots;

  final List<Map<String, String>> _medicineList = [
    {
      "name": "Paracetamol",
      "class": "Analgesic",
      "image": "assets/paracetamol.jpg",
    },
    {"name": "Ibuprofen", "class": "NSAID", "image": "assets/ibuprofen.jpg"},
    {
      "name": "Amoxicillin",
      "class": "Antibiotic",
      "image": "assets/Amoxicillin.jpg",
    },
    {
      "name": "Azithromycin",
      "class": "Antibiotic",
      "image": "assets/Azithromycin.jpeg",
    },
    {
      "name": "Metformin",
      "class": "Antidiabetic",
      "image": "assets/metformin.jpg",
    },
    {
      "name": "Lisinopril",
      "class": "Antihypertensive",
      "image": "assets/Lisinopril.jpg",
    },
    {
      "name": "Amlodipine",
      "class": "Calcium Channel Blocker",
      "image": "assets/Amlodipine.jpg",
    },
    {
      "name": "Simvastatin",
      "class": "Statin",
      "image": "assets/Simvastatin.jpg",
    },
    {"name": "Omeprazole", "class": "PPI", "image": "assets/Omeprazole.jpg"},
    {
      "name": "Atorvastatin",
      "class": "Statin",
      "image": "assets/ATORVASTATIN.jpg",
    },
    {
      "name": "Salbutamol",
      "class": "Bronchodilator",
      "image": "assets/Salbutamol.jpg",
    },
    {
      "name": "Furosemide",
      "class": "Diuretic",
      "image": "assets/Furosemide.jpg",
    },
    {
      "name": "Cetirizine",
      "class": "Antihistamine",
      "image": "assets/Cetirizine.jpg",
    },
    {
      "name": "Ranitidine",
      "class": "H2 Blocker",
      "image": "assets/Ranitidine.jpg",
    },
    {
      "name": "Hydrochlorothiazide",
      "class": "Diuretic",
      "image": "assets/Hydrochlorothiazide.jpg",
    },
    {"name": "Losartan", "class": "ARB", "image": "assets/Losartan.png"},
    {
      "name": "Warfarin",
      "class": "Anticoagulant",
      "image": "assets/warfarin.jpg",
    },
    {
      "name": "Diazepam",
      "class": "Benzodiazepine",
      "image": "assets/Diazepam.jpg",
    },
    {
      "name": "Prednisone",
      "class": "Corticosteroid",
      "image": "assets/Prednisone.jpg",
    },
    {
      "name": "Doxycycline",
      "class": "Antibiotic",
      "image": "assets/Doxycycline.jpg",
    },
    {
      "name": "Nifedipine",
      "class": "Calcium Channel Blocker",
      "image": "assets/Nifedipine.png",
    },
    {
      "name": "Clopidogrel",
      "class": "Antiplatelet",
      "image": "assets/Clopidogrel.jpg",
    },
    {"name": "Aspirin", "class": "Antiplatelet", "image": "assets/Aspirin.jpg"},
    {"name": "Morphine", "class": "Opioid", "image": "assets/Morphine.jpg"},
    {"name": "Insulin", "class": "Hormone", "image": "assets/Insulin.jpg"},
    {
      "name": "Ciprofloxacin",
      "class": "Antibiotic",
      "image": "assets/Ciprofloxacin.png",
    },
    {
      "name": "Metoprolol",
      "class": "Beta Blocker",
      "image": "assets/Metoprolol.jpeg",
    },
    {
      "name": "Levothyroxine",
      "class": "Hormone",
      "image": "assets/Levothyroxine.jpg",
    },
    {
      "name": "Loperamide",
      "class": "Antidiarrheal",
      "image": "assets/Loperamide.jpg",
    },
    {
      "name": "Glibenclamide",
      "class": "Antidiabetic",
      "image": "assets/Glibenclamide.jpg",
    },
  ];

  final _formKey = GlobalKey<FormState>();
  String? selectedMedicine;
  String? selectedDosage;
  String? selectedCategory;
  File? selectedImage;
  bool isCustom = false;
  final TextEditingController customMedController = TextEditingController();
  final TextEditingController customDosageController = TextEditingController();
  final TextEditingController customCategoryController =
      TextEditingController();
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool isEditing = false;
  String? editingMedId;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  void _openAddMedicationForm({model.Medication? med}) {
    if (med != null) {
      // Pre-fill for editing
      isEditing = true;
      editingMedId = med.id;
      selectedMedicine = med.name;
      selectedDosage = med.dosage;
      timesPerDay = med.times.length;
      selectedTimes = List<String>.from(med.times);
      selectedCategory = med.category;
      selectedImage = med.customImage;
      takenWhen = med.takenWhen;
      takenWithController.text = med.takenWith ?? '';
      selectedStartDate = med.startDate;
      selectedEndDate = med.endDate;
      if (!_medicineList.any((m) => m['name'] == med.name)) {
        isCustom = true;
        customMedController.text = med.name;
        customCategoryController.text = med.category;
      } else {
        isCustom = false;
      }
    } else {
      isEditing = false;
      editingMedId = null;
      selectedMedicine = null;
      selectedDosage = null;
      timesPerDay = 1;
      selectedTimes = _suggestTimes(1, context);
      selectedCategory = null;
      selectedImage = null;
      takenWhen = null;
      takenWithController.clear();
      selectedStartDate = null;
      selectedEndDate = null;
      isCustom = false;
      customMedController.clear();
      customDosageController.clear();
      customCategoryController.clear();
    }
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Medication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedMedicine,
                    decoration: const InputDecoration(
                      labelText: 'Select Medicine',
                    ),
                    validator: (value) =>
                        value == null ? 'Please select a medicine' : null,
                    items:
                        _medicineList.map((med) {
                          return DropdownMenuItem(
                            value: med['name'],
                            child: Text(med['name']!),
                          );
                        }).toList()..add(
                          const DropdownMenuItem(
                            value: 'Custom',
                            child: Text('Add Custom'),
                          ),
                        ),
                    onChanged: (value) {
                      setState(() {
                        selectedMedicine = value;
                        isCustom = value == 'Custom';
                      });
                    },
                  ),
                  if (isCustom) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: customMedController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Medicine Name',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter medicine name'
                          : null,
                    ),
                    TextFormField(
                      controller: customCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Class/Category',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter class/category'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Medicine Image'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedDosage,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                    validator: (val) => val == null ? 'Select dosage' : null,
                    items: _dosages
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedDosage = val),
                  ),
                  if (selectedDosage == 'Other')
                    TextFormField(
                      controller: customDosageController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Dosage',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter dosage' : null,
                    ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: timesPerDay,
                    decoration: const InputDecoration(
                      labelText: 'How many times per day?',
                    ),
                    items: [1, 2, 3]
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text('$n times'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          timesPerDay = val;
                          selectedTimes = _suggestTimes(val, context);
                        });
                      }
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Times to Take Medication',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...List.generate(timesPerDay, (i) {
                        final time = selectedTimes.length > i
                            ? selectedTimes[i]
                            : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Time ${i + 1}',
                                    hintText: time.isNotEmpty
                                        ? time
                                        : 'Select time',
                                  ),
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: time.isNotEmpty
                                          ? _parseTimeOfDay(time, context)
                                          : TimeOfDay(
                                              hour:
                                                  8 +
                                                  (i *
                                                      (timesPerDay == 2
                                                          ? 8
                                                          : 4)),
                                              minute: 0,
                                            ),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        if (selectedTimes.length > i) {
                                          selectedTimes[i] = picked.format(
                                            context,
                                          );
                                        } else {
                                          selectedTimes.add(
                                            picked.format(context),
                                          );
                                        }
                                      });
                                    }
                                  },
                                  validator: (val) =>
                                      (selectedTimes.length <= i ||
                                          selectedTimes[i].isEmpty)
                                      ? 'Select time'
                                      : null,
                                  controller: TextEditingController(text: time),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Taken When?'),
                    items: ['Before Food', 'After Food', 'With Food']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        takenWhen = val;
                      });
                    },
                  ),
                  TextFormField(
                    controller: takenWithController,
                    decoration: const InputDecoration(
                      labelText: 'Taken With (e.g., Water, Juice)',
                    ),
                    onChanged: (val) {
                      // Handle 'taken with' input value if needed in state
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            hintText: selectedStartDate != null
                                ? selectedStartDate!.toLocal().toString().split(
                                    ' ',
                                  )[0]
                                : 'Select',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedStartDate = picked);
                            }
                          },
                          validator: (val) => selectedStartDate == null
                              ? 'Select start date'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            hintText: selectedEndDate != null
                                ? selectedEndDate!.toLocal().toString().split(
                                    ' ',
                                  )[0]
                                : 'Select',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedEndDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedEndDate = picked);
                            }
                          },
                          validator: (val) => selectedEndDate == null
                              ? 'Select end date'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final name = isCustom
                            ? customMedController.text
                            : selectedMedicine!;
                        final dosage = selectedDosage == 'Other'
                            ? customDosageController.text
                            : selectedDosage!;
                        String category = 'Unclassified';
                        String image = '';
                        if (!isCustom) {
                          try {
                            category =
                                _medicineList.firstWhere(
                                  (m) => m['name'] == selectedMedicine,
                                )['class'] ??
                                'Unclassified';
                            image =
                                _medicineList.firstWhere(
                                  (m) => m['name'] == selectedMedicine,
                                )['image'] ??
                                '';
                          } catch (e) {
                            debugPrint('Error finding selected medicine: $e');
                          }
                        } else {
                          category = customCategoryController.text;
                        }
                        final med = model.Medication(
                          id: isEditing ? editingMedId! : const Uuid().v4(),
                          name: name,
                          dosage: dosage,
                          times: selectedTimes,
                          category: category,
                          imageUrl: image,
                          customImage: selectedImage,
                          takenWhen: takenWhen,
                          takenWith: takenWithController.text,
                          startDate: selectedStartDate,
                          endDate: selectedEndDate,
                        );
                        final medProvider =
                            Provider.of<provider.MedicationProvider>(
                              context,
                              listen: false,
                            );
                        if (isEditing) {
                          medProvider.updateMedication(med);
                        } else {
                          medProvider.addMedication(med);
                        }
                        // --- Notification logic ---
                        // Try to parse the time string to get the next occurrence
                        final now = DateTime.now();
                        for (final time in med.times) {
                          final timeParts = time.split(' - ');
                          final timeOfDayStr = timeParts[0];
                          final timeOfDay = TimeOfDay(
                            hour: int.parse(timeOfDayStr.split(':')[0]),
                            minute: int.parse(
                              timeOfDayStr.split(':')[1].split(' ')[0],
                            ),
                          );
                          DateTime medDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            timeOfDay.hour,
                            timeOfDay.minute,
                          );
                          if (medDateTime.isBefore(now)) {
                            medDateTime = medDateTime.add(
                              const Duration(days: 1),
                            );
                          }
                          final notifTime = medDateTime.subtract(
                            const Duration(hours: 2),
                          );
                          if (notifTime.isAfter(now)) {
                            tz.initializeTimeZones();
                            await flutterLocalNotificationsPlugin.zonedSchedule(
                              med.id.hashCode,
                              'Medication Reminder',
                              'Time to take $name ($dosage) at ${timeOfDay.format(context)}',
                              tz.TZDateTime.from(notifTime, tz.local),
                              const NotificationDetails(
                                android: AndroidNotificationDetails(
                                  'medication_channel',
                                  'Medications',
                                  channelDescription:
                                      'Reminders for taking medication',
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
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(isEditing ? 'Update' : 'Save'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medications = Provider.of<provider.MedicationProvider>(
      context,
    ).medications;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Medication Schedule',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        onPressed: _openAddMedicationForm,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: medications.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.6,
          ),
          itemBuilder: (context, index) {
            final med = medications[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Theme.of(context).colorScheme.surface,
              child: SizedBox(
                height: 320, // Adjust as needed for your design
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 140,
                        child: med.customImage != null
                            ? Image.file(
                                med.customImage!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              )
                            : Image.asset(
                                med.imageUrl,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        med.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        med.dosage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        med.times.join(', '),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (med.takenWhen != null) ...[
                        Text(
                          'Taken:  ${med.takenWhen}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                      if (med.takenWith != null &&
                          med.takenWith!.isNotEmpty) ...[
                        Text(
                          'With: ${med.takenWith}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                      if (med.startDate != null && med.endDate != null)
                        Text(
                          'From: ${med.startDate!.toLocal().toString().split(' ')[0]}\nTo: ${med.endDate!.toLocal().toString().split(' ')[0]}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openAddMedicationForm(med: med),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Provider.of<provider.MedicationProvider>(
                                context,
                                listen: false,
                              ).removeMedicationById(med.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Add these helper methods to the _MedicationScreenState class:
List<String> _suggestTimes(int timesPerDay, BuildContext context) {
  if (timesPerDay == 1) {
    return [TimeOfDay.now().format(context)];
  } else if (timesPerDay == 2) {
    return [
      TimeOfDay(hour: 8, minute: 0).format(context),
      TimeOfDay(hour: 16, minute: 0).format(context),
    ];
  } else if (timesPerDay == 3) {
    return [
      TimeOfDay(hour: 8, minute: 0).format(context),
      TimeOfDay(hour: 12, minute: 0).format(context),
      TimeOfDay(hour: 16, minute: 0).format(context),
    ];
  }
  return [];
}

TimeOfDay _parseTimeOfDay(String formatted, BuildContext context) {
  // Try to parse as HH:mm or h:mm a
  final timeRegExp = RegExp(r'^(\d{1,2}):(\d{2})');
  final match = timeRegExp.firstMatch(formatted);
  if (match != null) {
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
  // Fallback to 8:00
  return TimeOfDay(hour: 8, minute: 0);
}
