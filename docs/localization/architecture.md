# WorkKit Localization Architecture

WorkKit uses Flutter's official `gen_l10n` pipeline.

## Supported locales

- `en` — English (template and fallback)
- `vi` — Tiếng Việt
- system default — resolves to a supported locale; unsupported device locales fall back to English

## Data flow

1. ARB files live in `lib/l10n/`.
2. `flutter gen-l10n` generates `AppLocalizations` into source.
3. `WorkKitApp` configures localization delegates and supported locales.
4. `localePreferenceProvider` watches the `locale` row in Drift `AppSettings`.
5. Settings writes `system`, `vi`, or `en` through `LocaleRepository`.
6. Drift emits the new preference and `MaterialApp` rebuilds immediately.

The domain/data layers do not depend on BuildContext or generated localization classes. Presentation converts operational failures into localized user-facing messages.
