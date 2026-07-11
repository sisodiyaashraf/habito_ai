# habito_ai

A new Flutter project.

## 🚀 Play Store Deployment Guide

To ensure maximum security and compliance when deploying to the Google Play Store, follow these steps:

### 1. Secure API Key (Obfuscation)
Instead of using the `.env` file (which is insecure for production), build the app using `--dart-define`. This embeds the key into the binary and obfuscates it during the build process.

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_actual_api_key_here
# OR for App Bundle (Recommended for Play Store)
flutter build appbundle --release --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

### 2. Signing the App
You must sign your app with an upload key before publishing. 
1. Generate a keystore file.
2. Create a `key.properties` file in the `android/` folder.
3. Update `android/app/build.gradle.kts` to reference your signing configuration.

[Follow the official Flutter guide for signing](https://docs.flutter.dev/deployment/android#signing-the-app)

### 3. Permissions & Privacy
*   **Privacy Policy**: Google Play requires a Privacy Policy URL. Since this app tracks habits and uses AI, ensure your policy mentions that data is stored locally (Hive) and AI processing is done via Google Gemini.
*   **Notification Policy**: The app uses `SCHEDULE_EXACT_ALARM`. You may need to declare why this is necessary for your habit reminders in the Play Console.

### 4. Security Hardening
The app is already configured with:
*   **R8 Minification**: Shrinks and obfuscates code.
*   **Resource Shrinking**: Removes unused resources to reduce APK size.
*   **AI Safety Shields**: Built-in filters to block harmful or inappropriate content.
*   **Neural Throttling**: Client-side rate limits (15/hr, 50/day) to prevent API abuse.

---

