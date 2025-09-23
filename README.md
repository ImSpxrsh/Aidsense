# AidSense Flutter App (Firebase Authentication)

This project is a Flutter front-end scaffold integrated with Firebase Authentication for Android, iOS, and Web.

## What is included
- Flutter app with screens:
  - Welcome -> Onboarding -> Login -> Signup -> Reset Password -> Home
- Firebase initialization (lib/firebase_options.dart) using your provided configs
- `android_google_services.json` and `ios_GoogleService-Info.plist` included at project root (please move them to platform folders as described)
- Web firebase init snippet at web/firebase_init.js

## How to run

1. Install Flutter SDK.

2. Place platform config files:
   - Android: move `android_google_services.json` to `android/app/google-services.json`
   - iOS: move `ios_GoogleService-Info.plist` to `ios/Runner/GoogleService-Info.plist`

3. (Optional) If you want to use Android Gradle plugin, ensure `android/build.gradle` has google-services plugin added. If you used `flutter create`, these files will be present.

4. From project root:
   ```
   flutter pub get
   flutter run
   ```

5. For iOS: open `ios/Runner.xcworkspace` in Xcode, ensure signing & capabilities are set, then run in simulator.

6. For Web:
   ```
   flutter run -d chrome
   ```

## Notes
- Email/password sign up sends verification email (optional).
- Password reset sends an email via Firebase Auth.
- Replace the placeholder images in `assets/images/` with higher-res exports if needed.

If you want, I can package this into a ZIP file now.