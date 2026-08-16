# Adding a Language

1. Copy `lib/l10n/app_en.arb` to `app_<locale>.arb`.
2. Translate every user-facing value while keeping keys and placeholders unchanged.
3. Add `Locale('<locale>')` to `WorkKitApp.supportedLocales`.
4. Add an `AppLocalePreference` option only if the locale should be selectable explicitly in Settings.
5. Add the language label to Settings and translations.
6. Run `flutter gen-l10n`.
7. Add widget tests for the new locale and large text.
8. Verify native permission strings if the platform requires localized permission copy.

Never localize the WorkKit brand name.
