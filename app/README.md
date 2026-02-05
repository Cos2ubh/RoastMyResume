# Roast My Resume - Mobile App

Mobile version of the Roast My Resume application for Android and iOS devices.

## Features

- Native Android and iOS support
- Same beautiful gradient UI as the web version
- PDF file picker for mobile devices
- Optimized for touchscreen interactions

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run on Android emulator:
   ```bash
   flutter run
   ```

3. Or run on iOS simulator (macOS only):
   ```bash
   flutter run -d ios
   ```

## Backend Connection

Make sure the backend server is running on `http://localhost:8000` before testing the app. For physical devices, you'll need to update the URL in `lib/main.dart` to point to your computer's IP address.

## Build for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```
