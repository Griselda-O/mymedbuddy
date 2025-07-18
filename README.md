# MyMedBuddy

## Overview
MyMedBuddy is a comprehensive personal health and medication management app built with Flutter. It enables users to manage their daily health routines, including medications, appointments, health logs, and personal preferences. The app is designed to be multi-screen, interactive, persistent, and personalized, with robust notification and analytics features.

## Features
- **User Onboarding:** Collects user details (name, age, condition, reminder preferences) and persists them securely.
- **Multi-Screen Navigation:** Home, Medications, Appointments, Health Logs, Health Tips, and Profile screens, accessible via a bottom navigation bar.
- **Medication Management:** Add, edit, and track medications with support for multiple daily doses, compliance streaks, and missed dose detection.
- **Appointment Scheduling:** Add, edit, and view appointments with optional reminders and notification support.
- **Health Logs:** Log daily mood, symptoms, vitals, and notes. Includes analytics such as mood trends, symptom frequency, and streaks.
- **Profile Management:** View and edit user profile, health stats, and preferences (including dark mode).
- **Notifications:** Local notifications for medication and appointment reminders, with exact alarm support on Android.
- **Data Persistence:** Uses SharedPreferences for secure, persistent storage of user data and preferences.
- **API Integration:** Fetches health tips from a public API and/or Firebase.
- **State Management:** Utilizes Provider and Riverpod for robust, scalable state management.
- **Multi-User Support:** Allows switching between multiple user profiles.
- **Dark/Light Mode:** Fully supports both light and dark themes.

## Architecture & Main Files
- `lib/main.dart`: App entry point, initializes providers, notifications, and theme.
- `lib/screens/`: Contains all UI screens (onboarding, home, medications, appointments, health logs, profile, health tips, user selection).
- `lib/models/`: Data models for medications, appointments, and health logs.
- `lib/providers/`: State management using Provider and Riverpod.
- `lib/services/`: Business logic for notifications, API calls, and persistent storage.
- `assets/`: App images and icons.

## State Management
- **Provider:** Used for app-wide state (medications, appointments, theme).
- **Riverpod:** Used for advanced state and analytics in health logs.

## Notifications
- Uses `flutter_local_notifications` for scheduling and displaying notifications.
- Handles exact alarm permissions and notification permissions on Android.
- Supports custom sounds and notification actions.

## Data Persistence
- Uses `SharedPreferences` for storing user data, preferences, and health logs.
- Includes robust error handling and data recovery for corrupted or missing data.

## API Integration
- Fetches health tips from a public API and/or Firebase Realtime Database.
- Handles async loading and error states gracefully.

## Setup Instructions
1. **Clone the Repository:**
   ```
   git clone <your-repo-url>
   cd mymedbuddy_new
   ```
2. **Install Dependencies:**
   ```
   flutter pub get
   ```
3. **Run the App:**
   ```
   flutter run
   ```
   - For Android, ensure you have the correct NDK version and permissions set in your emulator/device.
   - For iOS, ensure you have CocoaPods installed and run `pod install` in the `ios/` directory if needed.

4. **Testing:**
   - Run widget tests with:
     ```
     flutter test
     ```

## Main Dependencies
- `flutter_local_notifications`
- `provider`
- `flutter_riverpod`
- `shared_preferences`
- `http`
- `android_intent_plus`
- `permission_handler`

## Credits
Developed by Griselda for academic coursework. For questions or contributions, please contact the project maintainer.
