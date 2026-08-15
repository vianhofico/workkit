# Project Status

## Current milestone

M3 — OCR

## Completed

### M0 — Foundation
Flutter shell, Material 3, Riverpod, go_router, Drift, safe local files, tests and CI.

### M1 — Document Library
Managed import/storage, metadata, recent/search/favorites, rename/delete/share, image preview and storage reporting.

### M2 — Scanner
Android ML Kit / iOS VisionKit scanner, multi-page image/PDF output, native crop/enhancement, platform bootstrap and green Android APK CI build.

## M3 — implemented in current branch

- Latin on-device OCR adapter with ML Kit Text Recognition
- Image OCR
- PDF page rendering with pdf_manipulator followed by ML Kit OCR
- Editable OCR text stored in Drift `OcrResults`
- Smart extraction for email, phone, date, URL and money values
- Vietnamese and English deterministic fixture tests
- OCR route integrated into Tools

## Next code task

Get M3 CI green, merge it, then implement M4 PDF Toolkit on the same streaming PDF engine.
