import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/core/localization/app_locale.dart';

class LocaleRepository {
  const LocaleRepository(this._database);

  final AppDatabase _database;

  Stream<AppLocalePreference> watchPreference() {
    final query = _database.select(_database.appSettings)
      ..where((row) => row.key.equals('locale'));
    return query.watchSingleOrNull().map(
          (row) => AppLocalePreference.fromStorage(row?.value),
        );
  }

  Future<void> setPreference(AppLocalePreference preference) async {
    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'locale',
            value: preference.storageValue,
          ),
        );
  }
}

final Provider<LocaleRepository> localeRepositoryProvider =
    Provider<LocaleRepository>((ref) {
  return LocaleRepository(ref.watch(appDatabaseProvider));
});

final StreamProvider<AppLocalePreference> localePreferenceProvider =
    StreamProvider<AppLocalePreference>((ref) {
  return ref.watch(localeRepositoryProvider).watchPreference();
});
