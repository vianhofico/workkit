import 'package:flutter/widgets.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/l10n/app_localizations.dart';

extension WorkKitLocalization on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String localizedFailure(AppFailure error) {
    return switch (error) {
      StorageFailure() => l10n.errorStorage,
      DatabaseFailure() => l10n.errorDatabase,
      ProcessingFailure() => l10n.errorProcessing,
    };
  }
}
