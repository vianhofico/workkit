import 'package:flutter/material.dart';

enum AppLocalePreference {
  system('system'),
  vietnamese('vi'),
  english('en');

  const AppLocalePreference(this.storageValue);

  final String storageValue;

  Locale? get locale => switch (this) {
        AppLocalePreference.system => null,
        AppLocalePreference.vietnamese => const Locale('vi'),
        AppLocalePreference.english => const Locale('en'),
      };

  static AppLocalePreference fromStorage(String? value) {
    return AppLocalePreference.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AppLocalePreference.system,
    );
  }
}
