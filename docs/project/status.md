# Project Status

## Current milestone

M6 — Image Toolkit

## Completed

- M0 Foundation
- M1 Document Library
- M2 Native Scanner + Android/iOS bootstrap
- M3 On-device OCR + smart extraction
- M4 Streaming PDF Toolkit
- M5 Local signatures + QR tools

## M6 — implemented in current branch

- Local image compression with format-aware encoding
- Resize with locked or unlocked aspect ratio
- Pixel-coordinate crop with bounds validation
- JPG, PNG, and lossless WebP conversion
- EXIF, embedded text, and ICC profile metadata removal
- Heavy decode/transform/encode work runs outside the UI isolate
- Managed-copy persistence with original files never overwritten
- Engine tests for resize, crop, WebP output, metadata removal, and invalid bounds

## Next code task

Get M6 CI green, merge it, then implement M7 Production Hardening.
