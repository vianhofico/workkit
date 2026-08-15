# WorkKit Architecture

WorkKit is local-first. Core document, OCR, PDF, image, QR, signature, backup and note flows remain useful without an account or backend.

```text
Presentation
    ↓
Application / Actions + Job Journal
    ↓
Domain
    ↓
Repositories / Services
    ↓
SQLite + App File Storage + Native APIs
```

Rules:

1. Domain contracts do not depend on widgets.
2. Database and file implementations stay behind repository/service boundaries.
3. Network access is optional for the core product.
4. Sensitive content and passwords must never be written to production logs.
5. Long-running file transforms write to temporary output before finalization and journal their state.
6. Startup recovery only deletes WorkKit-owned temp patterns; user originals are never targeted.
7. Backup/restore streams file payloads, validates its manifest/path boundaries and stages files before replacing database records.
8. Release signing material is supplied only through environment variables/GitHub Secrets and is not stored in source control.
