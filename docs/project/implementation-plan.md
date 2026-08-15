# Implementation Plan

## M0 — Foundation
Status: Complete
- [x] Flutter shell, theme, routing, Riverpod, Drift, local storage, tests and CI

## M1 — Document Library
Status: Complete
- [x] Import, managed storage, metadata, recent/search/favorites
- [x] Rename/delete/share, previews, storage usage and lifecycle tests

## Platform bootstrap
Status: Code complete; physical validation pending
- [x] Reproducible Android/iOS generation
- [x] iOS deployment target and camera permission
- [x] Android debug APK build in CI
- [ ] Physical Android smoke test — external validation

## M2 — Scanner
Status: Code complete; physical validation pending
- [x] Android ML Kit / iOS VisionKit native scanner
- [x] Multi-page scan and native crop/rotate/enhancement
- [x] Save as images/PDF, cancellation/error handling and service tests
- [ ] Physical-device integration smoke test — external validation

## M3 — OCR
Status: Complete
- [x] Android/iOS ML Kit Latin implementation
- [x] Image/PDF OCR pipeline and editable local text
- [x] Smart extraction and Vietnamese/English fixtures

## M4 — PDF Toolkit
Status: Complete
- [x] Image to PDF
- [x] Merge
- [x] Split
- [x] Reorder
- [x] Rotate
- [x] Delete pages
- [x] PDF to images
- [x] Password/encrypted-file handling
- [x] Large-file streaming strategy

## M5 — Signature and QR
Status: Complete
- [x] Draw/save signatures locally
- [x] Place/resize/rotate signature on PDF
- [x] QR scan
- [x] QR generation
- [x] QR history

## M6 — Image Toolkit
Status: Complete
- [x] Compress
- [x] Resize
- [x] Crop
- [x] JPG/PNG/WebP conversion
- [x] Metadata removal

## M7 — Production Hardening
Status: Code complete; external release validation pending
- [x] Accessibility pass + 200% text regression gate
- [x] Low-storage recovery and abandoned-temp cleanup
- [x] App-killed recovery journal for long jobs
- [x] Streaming local backup/restore
- [x] Security/privacy review
- [x] CI performance regression profiling + physical profile checklist
- [x] Android release AAB build and signed-AAB workflow
- [ ] Play Store internal testing — external Play Console validation

See `docs/project/external-validation.md` for the remaining hardware/account-bound checks.
