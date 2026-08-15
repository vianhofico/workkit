# WorkKit

WorkKit is a free-first, local-first mobile toolkit for everyday document work.

## M0 — Foundation

This branch establishes the production foundation for the app: Flutter shell, Material 3 theme, Riverpod, go_router, Drift/SQLite, safe local file writes, document repository abstraction, tests, and CI.

## Product principles

- Free-first
- Offline/local-first
- Privacy-first
- No account required for core features
- Never overwrite source documents by default
- Never log document content, OCR text, signatures, QR payloads, or API keys

## Development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

The Android/iOS platform folders will be generated and committed as the next foundation step before device builds are enabled in CI.
