# Security and privacy review

## Data inventory

WorkKit stores imported/generated documents, OCR text, signatures, QR history, settings and tool-job metadata locally. Core document tools do not require an account or backend.

## Review findings and controls

- Original user files are not overwritten by processing tools; generated outputs become managed copies.
- Sensitive document contents and PDF passwords are not intentionally written to application logs.
- PDF passwords are passed only to the active local operation and are not persisted by WorkKit.
- QR scan/generation history stores the QR content locally; scanned URLs are not automatically opened.
- Temporary PDF/OCR/image/signature files are cleaned after successful work and abandoned WorkKit temp files are recovered on startup.
- Long-running operations use a local job journal so app termination can be reported as interrupted instead of silently appearing complete.
- Restore only accepts the WorkKit backup magic/version, bounds manifest size, validates file lengths, rejects unsafe relative paths, and stages payloads before database replacement.
- Backup files intentionally remain user-portable and are **not encrypted**. The UI warns users to store them securely. Device/platform encryption and the destination chosen through the share sheet are outside WorkKit's backup format.
- The release workflow reads Android signing credentials only from GitHub Secrets/environment variables and does not commit a keystore or password.

## Re-review triggers

Repeat this review before adding analytics, crash-report payloads, cloud sync, accounts, remote OCR/AI, automatic URL opening, or any server-side document processing.
