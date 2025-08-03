@echo off
echo AidSense Development Setup
echo Congressional App Challenge - Essential Services for NJ-09
echo.

echo This script sets up the Flutter development environment.
echo Note: This is for DEVELOPMENT only. The actual app will be:
echo - Mobile app (Android/iOS)
echo - Web app (browser-based)
echo - No desktop installation required for end users
echo.

echo Adding Flutter to PATH temporarily...
set PATH=%CD%\flutter\bin;%PATH%

echo.
echo Installing Flutter dependencies...
flutter packages get

echo.
echo Firebase Setup Required:
echo 1. Create Firebase project at https://console.firebase.google.com
echo 2. Enable Authentication (Email/Password and Anonymous)
echo 3. Enable Firestore Database
echo 4. Add configuration files:
echo    - android/app/google-services.json (for Android)
echo    - ios/Runner/GoogleService-Info.plist (for iOS)
echo    - web/firebase-config.js (for Web)
echo.

echo.
echo Free API Setup:
echo 1. Get Hugging Face API key (free): https://huggingface.co/
echo 2. Add to environment or code configuration
echo.

echo.
echo Running code generation for data models...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo Development Environment Ready!
echo.
echo To run the app:
echo flutter run (for mobile development)
echo flutter run -d chrome (for web development)
echo.
echo Target Users: Homeless and low-income individuals in NJ-09
echo Core Features: Food banks, shelters, healthcare, free WiFi
echo.
pause
