# WorkKit

WorkKit is a free-first, local-first mobile toolkit for everyday document work. Version 1.0 keeps core processing on-device and does not require an account or backend.

## Included tools

- Managed document library with import, search, favorites, rename, delete and share
- Native multi-page document scanner
- On-device OCR for images/PDFs with editable extracted text
- PDF merge/split/reorder/delete/rotate, image↔PDF and encrypted-PDF handling
- Reusable local signatures and PDF signature placement
- QR scan, generation and local history
- Image compression, resize, crop, JPG/PNG/WebP conversion and metadata removal
- Local streaming backup/restore, interrupted-job recovery and abandoned-temp cleanup

## Tech baseline

- Flutter stable / Dart >= 3.12
- Riverpod + go_router
- Drift + SQLite
- `file_selector` + `share_plus`
- Native/on-device document scanning and OCR
- No backend or account for core features

## Bootstrap platform folders

Android and iOS projects are reproducibly generated from source:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
dart run build_runner build
```

## Quality gates

```bash
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build appbundle --release
```

Pull requests run these gates in GitHub Actions. The `Android Release AAB` manual workflow can additionally build a release AAB signed with repository secrets; see `docs/release/android-internal-testing.md`.

## Product principles

- Free-first and offline/local-first
- Privacy-first
- Imported and generated files live in WorkKit-managed storage
- Source files are never overwritten by processing tools
- Sensitive document content and PDF passwords are not intentionally logged
- Backup bundles are portable and intentionally unencrypted; store them securely

## Release status

Repository implementation is code-complete through M7. Physical-device accessibility/performance/camera tests and Google Play internal testing remain account/hardware-bound validation tasks documented in `docs/project/external-validation.md`.
