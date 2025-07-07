# digital_diary_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Troubleshooting build errors

If the Android build fails with messages about missing symbols and v1 embedding removal, update all plugins to their latest versions:

```bash
flutter pub upgrade
```

After upgrading packages, clean and rebuild the project:

```bash
flutter clean
flutter build apk --release
```

If issues persist, verify that any local packages or plugins are compatible with Flutter's v2 embedding and update them if necessary.
