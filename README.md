# WorkKit

WorkKit is a free-first, local-first mobile toolkit for everyday document work.

## Current status

M0 Foundation and M1 Document Library are merged. M2 adds a native on-device document scanner using ML Kit on Android and VisionKit on iOS.

## Tech baseline

- Flutter stable / Dart >= 3.12
- Riverpod + go_router
- Drift + SQLite
- file_picker + share_plus
- doc_scan_flutter for native document scanning
- No backend or account for core features

## Bootstrap platform folders

Android and iOS projects are reproducibly generated from source. Run:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
dart run build_runner build
```

The bootstrap configures the iOS deployment target and camera permission needed by the scanner. CI runs the same bootstrap and builds an Android debug APK.

## Development

```bash
flutter analyze
flutter test
flutter run
```

## Product principles

- Free-first and offline/local-first
- Privacy-first
- Imported and scanned files are copied into WorkKit-managed storage
- Source files are never overwritten by default
- Sensitive document content is never logged

See `docs/project/implementation-plan.md` for the milestone roadmap.
