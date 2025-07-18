// API Service
// This service handles fetching health tips from a public API endpoint using HTTP requests.
// It provides a method to asynchronously fetch and parse health tips for use in the app.

import 'dart:convert'; // For decoding JSON responses
import 'package:http/http.dart' as http; // HTTP client for making requests

// ApiService provides static methods for API calls
class ApiService {
  static const String _baseUrl =
      'https://publicapis.dev/api/health'; // Base URL for health tips API

  // Fetches a list of health tips from the API
  static Future<List<String>> fetchHealthTips() async {
    final response = await http.get(Uri.parse(_baseUrl)); // Make GET request

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body); // Decode JSON response
      final List<dynamic> tips = jsonData['entries']; // Extract entries
      // Map each entry to its description as a string
      return tips.map<String>((e) => e['Description'].toString()).toList();
    } else {
      throw Exception('Failed to load health tips'); // Handle error
    }
  }
}
