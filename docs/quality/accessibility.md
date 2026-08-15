# Accessibility review

WorkKit's production accessibility baseline is:

- Material controls retain platform semantics and minimum touch targets.
- The primary bottom navigation has an explicit semantics container label.
- Critical actions use icon + visible text instead of icon-only meaning where practical.
- Destructive restore actions require an explicit confirmation dialog.
- A widget regression test renders the Tools surface at 200% text scale and fails on layout exceptions.
- Loading and error states are represented with visible text, not color alone.

## External validation before broad release

Run TalkBack/VoiceOver focus-order and screen-reader announcements on physical devices, including scanner, QR camera permission, signature drawing, file picker, share sheet, and restore confirmation. Automated widget tests cannot fully validate platform accessibility services.
