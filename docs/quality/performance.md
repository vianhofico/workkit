# Performance hardening

WorkKit keeps large transforms off the UI path where supported:

- Image decode/resize/crop/encode runs in a Dart isolate.
- PDF operations use file-backed sources/sinks rather than buffering entire PDFs in Dart memory.
- OCR renders PDF pages to temporary files and cleans them after processing.
- Backup/restore streams payload files in 64 KiB chunks instead of base64-encoding whole files.
- A representative image resize regression test guards against severe local-processing slowdowns in CI.

## Physical-device profile checklist

Before broad release, profile on at least one lower-memory Android device with Flutter DevTools/profile mode: a 20+ page PDF merge, 10-page OCR, a high-resolution image conversion, and a multi-hundred-MB backup/restore. Record peak memory, jank and task duration. Physical performance numbers are hardware-dependent and are not fabricated by CI.
