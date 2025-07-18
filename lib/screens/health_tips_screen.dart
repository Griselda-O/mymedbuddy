// This file defines a screen that fetches and displays a list of health tips with animated card effects.

import 'package:flutter/material.dart';
import '../services/health_tips_service.dart';

// Represents the UI for showing health tips.
class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  // A future that fetches the health tips data.
  late Future<List<String>> _tipsFuture;

  // Initialize the data fetch when the screen loads.
  @override
  void initState() {
    super.initState();
    _tipsFuture = HealthTipsService.fetchHealthTips();
  }

  // Builds the UI and handles different fetch states (loading, error, success).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Health Tips'),
        backgroundColor: const Color(0xFFDCC1A1),
      ),
      body: 
      // Use FutureBuilder to manage and display the loading, error, and success states for health tips data.
      FutureBuilder<List<String>>(
        future: _tipsFuture,
        builder: (context, snapshot) {
          // Loading state: show a progress indicator while waiting for data.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // Error state: display an error message if fetching fails.
          else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Oops! Couldn’t load tips.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          } 
          // Success state: display the list of health tips with animated cards.
          else if (snapshot.hasData) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) =>
                  // Animate each health tip card into view with a fade and vertical slide effect.
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 500 + (i * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Card(
                            color: Colors.white,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.health_and_safety, color: Color(0xFF935E3A)),
                              title: Text(
                                snapshot.data![i],
                                style: TextStyle(color: Colors.brown[800]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}