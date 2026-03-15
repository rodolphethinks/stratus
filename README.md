# Stratus

Minimalist weather app with forecast confidence.

**Live:** https://getstratus.web.app

Built with Flutter Web + Open-Meteo API. No ads, no account required.

## Features

- Current conditions with mood-adaptive background gradient
- 24-hour scrollable temperature curve
- 5-day forecast with absolute temperature colour scale
- Forecast confidence strip (high / medium / low by horizon)
- Nowcast pill — rain status with hourly precipitation bars
- Multi-city support with search
- Yesterday comparison toggle in settings
- PWA — installable from Chrome on Android / iOS

## Stack

- Flutter 3.32 (Dart 3.8)
- [Open-Meteo](https://open-meteo.com/) — free, no API key needed
- Firebase Hosting

## Run locally

```bash
flutter pub get
flutter run -d chrome --web-port 7777
```

## Deploy

```bash
flutter build web --release
firebase deploy --only hosting
```

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
