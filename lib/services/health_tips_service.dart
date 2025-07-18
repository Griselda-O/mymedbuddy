// Health Tips Service
// This service fetches health tips from a Firebase Realtime Database endpoint using HTTP requests.
// It provides a method to asynchronously fetch and parse health tips for use in the app.

import 'dart:convert'; // For decoding JSON responses
import 'package:http/http.dart' as http; // HTTP client for making requests

// HealthTipsService provides static methods for fetching health tips
class HealthTipsService {
  static const _firebaseUrl =
      'https://mymedbuddy-default-rtdb.firebaseio.com/health_tips.json'; // Firebase endpoint

  // Fetches a list of health tips from the Firebase database
  static Future<List<String>> fetchHealthTips() async {
    final response = await http.get(
      Uri.parse(_firebaseUrl),
    ); // Make GET request

    if (response.statusCode == 200) {
      final data = json.decode(response.body); // Decode JSON response
      if (data is List) {
        // If the data is a list, map each tip to a string
        return data.map<String>((tip) => tip.toString()).toList();
      } else {
        throw Exception('Unexpected data format'); // Handle unexpected format
      }
    } else {
      throw Exception('Failed to fetch health tips'); // Handle error
    }
  }
}
