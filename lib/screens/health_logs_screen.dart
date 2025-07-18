// Health Logs Screen: Log mood, symptoms, vitals, notes; view analytics
// Uses Riverpod for advanced state and analytics
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:uuid/uuid.dart';
import '../models/health_log.dart';
import '../providers/health_log_provider.dart';

const moodEmojis = ['😀', '😐', '😢', '😠', '😴', '😷', '🤒', '🥳', '😇', '😎'];
const symptomEmojis = [
  '🤧',
  '🤒',
  '🤕',
  '🤢',
  '🤮',
  '🥵',
  '🥶',
  '😵',
  '🤯',
  '😰',
  '🤬',
  '😱',
];
const vitalsList = ['BP', 'HR', 'Temp', 'SpO2'];

// Vitals dropdown options
const bpOptions = ['normal', 'high', 'low', 'custom'];
const hrOptions = ['normal', 'high', 'low', 'custom'];
const tempOptions = ['normal', 'fever', 'low', 'custom'];
const spo2Options = ['normal', 'low', 'custom'];

final moodFilterProvider = riverpod.StateProvider<String?>((ref) => null);
final healthLogListProvider = riverpod.Provider<List<HealthLog>>((ref) {
  // For now, just return an empty list; you can connect this to your Provider logic or a StateNotifier
  // Replace with actual logic as needed
  return [];
});
final filteredLogsProvider = riverpod.Provider<List<HealthLog>>((ref) {
  final logs = ref.watch(healthLogListProvider);
  final filter = ref.watch(moodFilterProvider);
  if (filter == null || filter.isEmpty) return logs;
  return logs.where((log) => log.mood == filter).toList();
});

class HealthLogsScreen extends riverpod.ConsumerStatefulWidget {
  const HealthLogsScreen({super.key});

  @override
  riverpod.ConsumerState<HealthLogsScreen> createState() =>
      _HealthLogsScreenState();
}

class _HealthLogsScreenState extends riverpod.ConsumerState<HealthLogsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedMood;
  List<String> _selectedSymptoms = [];
  Map<String, String> _vitals = {};
  bool _editing = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    // Provider.of<HealthLogProvider>(context, listen: false).loadLogs(); // Removed as per edit hint
  }

  void _submitLog() {
    if (_formKey.currentState!.validate() && _selectedMood != null) {
      final newLog = HealthLog(
        id: _editing ? _editingId! : const Uuid().v4(),
        date: DateTime.now(),
        mood: _selectedMood!,
        symptoms: List<String>.from(_selectedSymptoms),
        vitals: Map<String, String>.from(_vitals),
        notes: _notesController.text,
      );
      if (_editing) {
        ref.read(healthLogNotifierProvider.notifier).updateLog(newLog);
      } else {
        ref.read(healthLogNotifierProvider.notifier).addLog(newLog);
      }
      _notesController.clear();
      setState(() {
        _selectedMood = null;
        _selectedSymptoms = [];
        _vitals = {};
        _editing = false;
        _editingId = null;
      });
    }
  }

  void _editLog(HealthLog log) {
    setState(() {
      _editing = true;
      _editingId = log.id;
      _selectedMood = log.mood;
      _selectedSymptoms = List<String>.from(log.symptoms);
      _vitals = Map<String, String>.from(log.vitals);
      _notesController.text = log.notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(filteredLogsProvider);
    final selectedMoodFilter = ref.watch(moodFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Logs'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Wrap the form in a Card for visual separation
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log Your Health',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mood emoji picker
                        const Text(
                          'Mood:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...moodEmojis.map(
                                (emoji) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedMood = emoji),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedMood == emoji
                                          ? Colors.teal[100]
                                          : Colors.grey[200],
                                      border: Border.all(
                                        color: _selectedMood == emoji
                                            ? Colors.teal
                                            : Colors.grey[400]!,
                                        width: _selectedMood == emoji ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Symptom emoji multi-select
                        const Text(
                          'Symptoms:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...symptomEmojis.map(
                                (emoji) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedSymptoms.contains(emoji)) {
                                        _selectedSymptoms.remove(emoji);
                                      } else {
                                        _selectedSymptoms.add(emoji);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedSymptoms.contains(emoji)
                                          ? Colors.red[100]
                                          : Colors.grey[200],
                                      border: Border.all(
                                        color: _selectedSymptoms.contains(emoji)
                                            ? Colors.red
                                            : Colors.grey[400]!,
                                        width: _selectedSymptoms.contains(emoji)
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Vitals entry
                        const Text(
                          'Vitals:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            // BP
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _vitals['BP'],
                                    decoration: const InputDecoration(
                                      labelText: 'BP',
                                    ),
                                    items: bpOptions
                                        .map(
                                          (opt) => DropdownMenuItem(
                                            value: opt,
                                            child: Text(opt),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() => _vitals['BP'] = val ?? '');
                                    },
                                  ),
                                  if (_vitals['BP'] == 'custom')
                                    TextFormField(
                                      initialValue: '',
                                      decoration: const InputDecoration(
                                        labelText: 'Custom BP',
                                      ),
                                      onChanged: (val) => _vitals['BP'] = val,
                                    ),
                                ],
                              ),
                            ),
                            // HR
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _vitals['HR'],
                                    decoration: const InputDecoration(
                                      labelText: 'HR',
                                    ),
                                    items: hrOptions
                                        .map(
                                          (opt) => DropdownMenuItem(
                                            value: opt,
                                            child: Text(opt),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() => _vitals['HR'] = val ?? '');
                                    },
                                  ),
                                  if (_vitals['HR'] == 'custom')
                                    TextFormField(
                                      initialValue: '',
                                      decoration: const InputDecoration(
                                        labelText: 'Custom HR',
                                      ),
                                      onChanged: (val) => _vitals['HR'] = val,
                                    ),
                                ],
                              ),
                            ),
                            // Temp
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _vitals['Temp'],
                                    decoration: const InputDecoration(
                                      labelText: 'Temp',
                                    ),
                                    items: tempOptions
                                        .map(
                                          (opt) => DropdownMenuItem(
                                            value: opt,
                                            child: Text(opt),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(
                                        () => _vitals['Temp'] = val ?? '',
                                      );
                                    },
                                  ),
                                  if (_vitals['Temp'] == 'custom')
                                    TextFormField(
                                      initialValue: '',
                                      decoration: const InputDecoration(
                                        labelText: 'Custom Temp',
                                      ),
                                      onChanged: (val) => _vitals['Temp'] = val,
                                    ),
                                ],
                              ),
                            ),
                            // SpO2
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _vitals['SpO2'],
                                    decoration: const InputDecoration(
                                      labelText: 'SpO2',
                                    ),
                                    items: spo2Options
                                        .map(
                                          (opt) => DropdownMenuItem(
                                            value: opt,
                                            child: Text(opt),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(
                                        () => _vitals['SpO2'] = val ?? '',
                                      );
                                    },
                                  ),
                                  if (_vitals['SpO2'] == 'custom')
                                    TextFormField(
                                      initialValue: '',
                                      decoration: const InputDecoration(
                                        labelText: 'Custom SpO2',
                                      ),
                                      onChanged: (val) => _vitals['SpO2'] = val,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter notes'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: ElevatedButton(
                            onPressed: _submitLog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(160, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _editing ? 'Update Log' : 'Save Log',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 32, thickness: 1),
              const Text(
                'Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final logs = ref.watch(healthLogNotifierProvider);
                  // Mood trends (past 7 days)
                  final now = DateTime.now();
                  final moodCounts = <String, int>{};
                  for (int i = 0; i < 7; i++) {
                    final day = now.subtract(Duration(days: i));
                    final dayStr = day.toIso8601String().split('T')[0];
                    final log = logs.lastWhere(
                      (l) => l.date.toIso8601String().split('T')[0] == dayStr,
                      orElse: () => HealthLog(
                        id: '',
                        date: day,
                        mood: '',
                        symptoms: [],
                        vitals: {},
                        notes: '',
                      ),
                    );
                    if (log.mood.isNotEmpty) {
                      moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
                    }
                  }
                  // Symptom frequency
                  final symptomCounts = <String, int>{};
                  for (final log in logs) {
                    for (final s in log.symptoms) {
                      symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
                    }
                  }
                  final sortedSymptoms = symptomCounts.entries.toList();
                  sortedSymptoms.sort((a, b) => b.value.compareTo(a.value));
                  // Vitals averages (for numeric values)
                  double? avgHR;
                  double? avgTemp;
                  double? avgSpO2;
                  final hrVals = logs
                      .map((l) => double.tryParse(l.vitals['HR'] ?? ''))
                      .where((v) => v != null)
                      .cast<double>()
                      .toList();
                  final tempVals = logs
                      .map((l) => double.tryParse(l.vitals['Temp'] ?? ''))
                      .where((v) => v != null)
                      .cast<double>()
                      .toList();
                  final spo2Vals = logs
                      .map((l) => double.tryParse(l.vitals['SpO2'] ?? ''))
                      .where((v) => v != null)
                      .cast<double>()
                      .toList();
                  if (hrVals.isNotEmpty)
                    avgHR = hrVals.reduce((a, b) => a + b) / hrVals.length;
                  if (tempVals.isNotEmpty)
                    avgTemp =
                        tempVals.reduce((a, b) => a + b) / tempVals.length;
                  if (spo2Vals.isNotEmpty)
                    avgSpO2 =
                        spo2Vals.reduce((a, b) => a + b) / spo2Vals.length;
                  // UI
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mood Trends (Past 7 Days):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: moodEmojis.map((emoji) {
                          final count = moodCounts[emoji] ?? 0;
                          return Column(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                              Container(
                                width: 16,
                                height: (count * 16).toDouble(),
                                color: Colors.teal,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                              ),
                              Text(
                                '$count',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Most Frequent Symptoms:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: sortedSymptoms
                            .take(5)
                            .map(
                              (e) => Chip(label: Text('${e.key} (${e.value})')),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Vitals Averages:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('HR: ${avgHR?.toStringAsFixed(1) ?? '-'}'),
                          const SizedBox(width: 16),
                          Text('Temp: ${avgTemp?.toStringAsFixed(1) ?? '-'}'),
                          const SizedBox(width: 16),
                          Text('SpO2: ${avgSpO2?.toStringAsFixed(1) ?? '-'}'),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Advanced Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final logs = ref.watch(healthLogNotifierProvider);
                  // Calendar heatmap (last 30 days)
                  final now = DateTime.now();
                  final days = List.generate(
                    30,
                    (i) => now.subtract(Duration(days: 29 - i)),
                  );
                  final logDays = logs
                      .map((l) => l.date.toIso8601String().split('T')[0])
                      .toSet();
                  // Longest streak
                  int longestStreak = 0, currentStreak = 0;
                  for (int i = 0; i < days.length; i++) {
                    final dayStr = days[i].toIso8601String().split('T')[0];
                    if (logDays.contains(dayStr)) {
                      currentStreak++;
                      if (currentStreak > longestStreak)
                        longestStreak = currentStreak;
                    } else {
                      currentStreak = 0;
                    }
                  }
                  // Mood/symptom correlation
                  final moodSymptomMap = <String, Map<String, int>>{};
                  for (final log in logs) {
                    for (final s in log.symptoms) {
                      moodSymptomMap[log.mood] ??= {};
                      moodSymptomMap[log.mood]![s] =
                          (moodSymptomMap[log.mood]![s] ?? 0) + 1;
                    }
                  }
                  // Mood distribution (pie chart as colored bars)
                  final moodCounts = <String, int>{};
                  for (final log in logs) {
                    moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
                  }
                  final totalMoods = moodCounts.values.fold(0, (a, b) => a + b);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Activity (Last 30 Days):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: days.map((day) {
                          final dayStr = day.toIso8601String().split('T')[0];
                          final hasLog = logDays.contains(dayStr);
                          return Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: hasLog ? Colors.teal : Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text('Longest Logging Streak: $longestStreak days'),
                      const SizedBox(height: 14),
                      const Text(
                        'Mood/Symptom Correlation:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...moodSymptomMap.entries.map(
                        (entry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: entry.value.entries
                                  .map(
                                    (e) => Chip(
                                      label: Text('${e.key} (${e.value})'),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Mood Distribution:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: moodCounts.entries.map((e) {
                          final percent = totalMoods > 0
                              ? (e.value / totalMoods)
                              : 0.0;
                          return Container(
                            width: 40 + percent * 60,
                            height: 18,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${e.key} ${((percent * 100).toStringAsFixed(0))}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
              // Filter dropdown
              Row(
                children: [
                  const Text('Filter by mood: '),
                  DropdownButton<String>(
                    value: selectedMoodFilter,
                    hint: const Text('All'),
                    items: [null, ...moodEmojis]
                        .map(
                          (mood) => DropdownMenuItem(
                            value: mood,
                            child: Text(mood ?? 'All'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        ref.read(moodFilterProvider.notifier).state = val,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Recent Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Row(
                        children: [
                          Text(log.mood, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          ...log.symptoms.map(
                            (e) =>
                                Text(e, style: const TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vitals: ${log.vitals.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                          ),
                          Text(log.notes),
                          Text(log.date.toIso8601String()),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editLog(log),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              ref
                                  .read(healthLogNotifierProvider.notifier)
                                  .removeLog(log.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
