# Project Status

## Current state

WorkKit 1.0 code complete; external device/store validation pending.

## Completed in repository

- M0 Foundation
- M1 Document Library
- M2 Native Scanner implementation + reproducible Android/iOS bootstrap
- M3 On-device OCR + smart extraction
- M4 Streaming PDF Toolkit
- M5 Local signatures + QR tools
- M6 Local Image Toolkit
- M7 recovery, backup/restore, accessibility, privacy/security, performance and Android release hardening

## M7 production hardening

- Long-running OCR/PDF/image/signature operations are journaled as running/completed/failed and stale running jobs become interrupted after restart.
- Startup/manual storage recovery removes WorkKit-owned abandoned temporary outputs.
- Low-storage file-system failures are surfaced with an actionable recovery message.
- Backup/restore streams managed files and restores metadata/files from a validated staged bundle.
- Settings exposes create/share backup, restore confirmation and storage recovery.
- Accessibility and performance regression tests run in CI.
- Privacy/security and physical performance reviews are documented.
- Standard CI validates analyzer, tests, Android debug APK and release AAB.
- A separate workflow builds a signed release AAB when repository signing secrets are configured.

## External validation remaining

Real hardware and Play Console checks are intentionally tracked in `docs/project/external-validation.md`. These cannot be truthfully completed by repository CI alone.
