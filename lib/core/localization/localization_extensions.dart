import 'package:flutter/widgets.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/l10n/app_localizations.dart';

String localizeAppFailure(AppLocalizations l10n, AppFailure error) {
  return switch (error) {
    StorageFailure() => l10n.errorStorage,
    DatabaseFailure() => l10n.errorDatabase,
    ProcessingFailure() => l10n.errorProcessing,
  };
}

extension WorkKitLocalization on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String localizedFailure(AppFailure error) => localizeAppFailure(l10n, error);
}
