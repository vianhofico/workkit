# Project Status

## Current state

WorkKit 1.1.0 source is code-complete through M8 once the M8 branch passes CI and is merged. External physical-device/store validation remains separate because it cannot be truthfully completed by repository CI alone.

## Completed in repository

- M0 Foundation
- M1 Document Library
- M2 Native Scanner + reproducible Android/iOS bootstrap
- M3 On-device OCR + smart extraction
- M4 Streaming PDF Toolkit
- M5 Local signatures + QR tools
- M6 Local Image Toolkit
- M7 recovery, backup/restore, accessibility, privacy/security, performance and Android release hardening
- M8 Vietnamese/English localization, locale persistence and official WorkKit product identity/icon

## M8 localization and identity

- Product-facing name is `WorkKit`; the lowercase `workkit` identifier remains only where Dart/package/tooling rules require lowercase identifiers.
- UI supports English, Vietnamese and system-default locale selection.
- Locale preference is stored locally in the existing Drift `AppSettings` table and updates the app without restart.
- User-facing strings across navigation, Home, Files, Tools, Settings, Scanner, OCR, PDF, Signature, QR and Image Toolkit are localized.
- Dates, counts, dialogs, snackbars, tooltips and semantics participate in localization.
- OCR remains independent from UI locale and continues to use the on-device Latin recognition model optimized for Vietnamese and English text.
- The official WorkKit launcher icon is generated for Android/iOS during CI/release bootstrap.
- Android/iOS product display names are explicitly normalized to `WorkKit`.
- CI generates localization source and launcher icons before analyzer/tests/builds.

## External validation remaining

Physical hardware and Play Console checks remain tracked in `docs/project/external-validation.md`.
