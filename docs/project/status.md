# Project Status

## Current milestone

M2 — Scanner

## Completed

### M0 — Foundation

Flutter shell, Material 3 theme, Riverpod, go_router, Drift schema, local safe-file service, repository abstractions, tests and CI.

### M1 — Document Library

Device import, managed local copies, metadata persistence, recent files, search, favorites, rename, delete, share/export, image previews and storage reporting.

## M2 — implemented in current branch

- Reproducible Android/iOS platform bootstrap script
- Android debug APK build added to CI
- Scanner domain contract separated from native adapter
- ML Kit document scanning on Android through `doc_scan_flutter`
- VisionKit document scanning on iOS through `doc_scan_flutter`
- Native crop/edge detection/rotation/enhancement flow
- Scan to per-page images or PDF
- Cancellation handling
- Completed scans copied from temporary native paths into WorkKit managed storage
- Scanner lifecycle tests with native adapter replaced by a fake

## Next code task

Get M2 CI green, merge it, then implement M3 OCR with the same adapter/application/UI boundary.
