# Implementation Plan

## M0 — Foundation
Status: Complete
- [x] Flutter shell, theme, routing, Riverpod, Drift, local storage, tests and CI

## M1 — Document Library
Status: Complete
- [x] Import, managed storage, metadata, recent/search/favorites
- [x] Rename/delete/share, previews, storage usage and lifecycle tests

## Platform bootstrap
- [x] Reproducible Android/iOS generation
- [x] iOS deployment target and camera permission
- [x] Android debug APK build in CI
- [ ] Physical Android smoke test

## M2 — Scanner
Status: Complete
- [x] Android ML Kit / iOS VisionKit native scanner
- [x] Multi-page scan and native crop/rotate/enhancement
- [x] Save as images/PDF, cancellation/error handling and service tests
- [ ] Physical-device integration smoke test

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
Status: In review
- [x] Draw/save signatures locally
- [x] Place/resize/rotate signature on PDF
- [x] QR scan
- [x] QR generation
- [x] QR history

## M6 — Image Toolkit
- [ ] Compress
- [ ] Resize
- [ ] Crop
- [ ] JPG/PNG/WebP conversion
- [ ] Metadata removal

## M7 — Production Hardening
- [ ] Accessibility pass
- [ ] Low-storage recovery
- [ ] App-killed recovery for long jobs
- [ ] Backup/restore
- [ ] Security/privacy review
- [ ] Performance profiling
- [ ] Android AAB release workflow
- [ ] Play Store internal testing
