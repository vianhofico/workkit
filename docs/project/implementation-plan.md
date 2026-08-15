# Implementation Plan

## M0 — Foundation

Status: Complete

- [x] Product scope and architecture decisions
- [x] Flutter application shell
- [x] Material 3 light/dark theme
- [x] go_router navigation shell
- [x] Riverpod foundation
- [x] Drift schema v1
- [x] Local safe-file service
- [x] Universal action contract
- [x] Document repository abstraction and Drift implementation
- [x] Unit/widget test foundation
- [x] GitHub Actions quality workflow
- [x] First green CI on GitHub

## M1 — Document Library

Status: In review

- [x] Import files from device
- [x] Copy imports into WorkKit-managed local storage
- [x] Persist document metadata
- [x] Recent documents
- [x] Search
- [x] Favorites
- [x] Rename
- [x] Delete with confirmation
- [x] Share/export
- [x] Image preview thumbnails
- [x] Storage usage reporting
- [x] Repository/import lifecycle tests

## Platform bootstrap before M2

- [ ] Generate and commit Android platform folder
- [ ] Generate and commit iOS platform folder
- [ ] Add Android debug build to CI
- [ ] Verify file picker/share plugins on a real Android device

## M2 — Scanner

- [ ] Android ML Kit document scanner adapter
- [ ] iOS VisionKit adapter
- [ ] Multi-page scan
- [ ] Crop/rotate/filter flow
- [ ] Save scan as image/PDF
- [ ] Cancellation and permission states
- [ ] Device integration tests

## M3 — OCR

- [ ] OCR service interface
- [ ] Android ML Kit implementation
- [ ] iOS Vision implementation
- [ ] Image/PDF OCR pipeline
- [ ] Editable extracted text
- [ ] Smart extraction for phone/email/date/URL/money
- [ ] Vietnamese and English fixture suite

## M4 — PDF Toolkit

- [ ] Image to PDF
- [ ] Merge
- [ ] Split
- [ ] Reorder
- [ ] Rotate
- [ ] Delete pages
- [ ] PDF to images
- [ ] Password/encrypted-file handling
- [ ] Large-file streaming strategy

## M5 — Signature and QR

- [ ] Draw/save signatures locally
- [ ] Place/resize/rotate signature on PDF
- [ ] QR scan
- [ ] QR generation
- [ ] QR history

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
