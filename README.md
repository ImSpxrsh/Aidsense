# AidSense

A Flutter app for AI-powered healthcare assistance and local resource discovery.

## Features

- 🔐 Firebase Authentication (Email/Password, Google Sign-In)
- 💬 AI Chat Interface
- 📍 Location-based Services
- 🔔 Push Notifications
- 📱 Modern, Accessible UI
- 🌍 Multi-language Support

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI Screens
│   ├── login_screen.dart
│   └── home_screen.dart
├── services/                 # Business Logic Services
│   ├── auth_service.dart     # Firebase Authentication
│   ├── firestore_service.dart # Firestore Database
│   └── notification_service.dart # Push Notifications
├── models/                   # Data Models
│   ├── user_model.dart
│   ├── place_model.dart
│   ├── bookmark_model.dart
│   └── ...
└── widgets/                  # Reusable UI Components
    ├── change_theme_switch.dart
    ├── localization_button.dart
    └── ...
```

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Firebase Configuration**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files
   - Enable Authentication, Firestore, and Cloud Messaging in Firebase Console

3. **Run the App**
   ```bash
   flutter run
   ```

## Dependencies

- **Firebase**: Core, Auth, Firestore, Storage, Messaging
- **State Management**: flutter_bloc
- **UI**: Material Design 3, flutter_screenutil
- **Networking**: dio, retrofit
- **Localization**: flutter_localizations
- **Notifications**: flutter_local_notifications

## Development

The app is structured with a clean architecture approach:
- **Screens**: Handle UI and user interactions
- **Services**: Manage business logic and external APIs
- **Models**: Define data structures
- **Widgets**: Reusable UI components

## Contributing

1. Follow the existing code structure
2. Add proper error handling
3. Include unit tests for new features
4. Update documentation as needed

## License

This project is licensed under the MIT License.

