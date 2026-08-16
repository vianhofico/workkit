import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/core/localization/app_locale.dart';
import 'package:workkit/core/localization/locale_provider.dart';

void main() {
  late AppDatabase database;
  late LocaleRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocaleRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('defaults to system and persists Vietnamese preference', () async {
    expect(await repository.watchPreference().first, AppLocalePreference.system);

    await repository.setPreference(AppLocalePreference.vietnamese);
    expect(await repository.watchPreference().first, AppLocalePreference.vietnamese);

    await repository.setPreference(AppLocalePreference.english);
    expect(await repository.watchPreference().first, AppLocalePreference.english);
  });
}
