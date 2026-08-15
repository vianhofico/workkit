# WorkKit

WorkKit is a free-first, local-first mobile toolkit for everyday document work.

## Current status

**M0 — Foundation** is merged. **M1 — Document Library** is in development/review.

The app now has a persistent local document library with device import, managed local copies, recent files, search, favorites, rename, delete, sharing/export, image previews, and storage usage reporting.

## Tech baseline

- Flutter stable / Dart >= 3.12
- Riverpod
- go_router
- Drift + SQLite
- file_picker for native device import
- share_plus for platform share/export
- Android first, iOS-ready architecture

## Bootstrap platform folders

If this checkout does not yet include generated `android/` and `ios/` folders, run once from the repository root:

```bash
flutter create --org com.workkit --project-name workkit --platforms=android,ios .
flutter pub get
dart run build_runner build
```

Then run:

```bash
flutter run
```

## Quality checks

```bash
flutter analyze
flutter test
```

## Product principles

- Free-first
- Offline/local-first
- Privacy-first
- No account required for core features
- Imported source documents are copied into managed storage; originals are not modified
- Sensitive document content is never logged

See `docs/product/mvp-scope.md` and `docs/architecture/overview.md`.
