# External validation checklist

The application code and CI quality gates can be completed in the repository. The following checks require real hardware, operating-system UI, signing material, or the repository owner's Play Console account.

## Physical Android

- [ ] Launch/install smoke test on a supported physical Android device.
- [ ] Multi-page document scan, crop/rotate/enhancement, save images/PDF.
- [ ] OCR from camera/imported image and multi-page PDF.
- [ ] QR camera scan, torch/camera permission and QR generation history.
- [ ] Draw/save a signature and place/resize/rotate it on a PDF.
- [ ] Image compress/resize/crop/convert/metadata-removal smoke tests.
- [ ] Low-storage drill and `Recover storage` behavior.
- [ ] Kill the app during a long operation and confirm the next launch reports/reconciles the interrupted job.
- [ ] Create a backup, uninstall/clear app data in a controlled test, reinstall and restore the backup.
- [ ] TalkBack focus order and announcements at large font/display sizes.
- [ ] Profile representative large PDF/OCR/image/backup workloads.

## Android release / Play Console

- [ ] Create and securely retain an Android upload keystore.
- [ ] Add the four Android signing secrets documented in `docs/release/android-internal-testing.md`.
- [ ] Run `Android Release AAB` and verify the signed artifact installs through Play internal testing.
- [ ] Complete Play Console app-content/data-safety/store-listing requirements.
- [ ] Invite internal testers and close release-blocking findings.

## iOS physical smoke

- [ ] VisionKit scanner permission and multi-page scan on a physical iPhone/iPad.
- [ ] OCR, QR camera, signature and share-sheet flows.
- [ ] VoiceOver focus/announcement review.
