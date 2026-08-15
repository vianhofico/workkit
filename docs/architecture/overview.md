# WorkKit Architecture

WorkKit is local-first. Core document, OCR, PDF, image, QR, signature, and note flows must remain useful without an account or backend.

```text
Presentation
    ↓
Application / Actions
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
4. Sensitive content must never be written to production logs.
5. Long-running file transforms write to temporary output before finalization.
