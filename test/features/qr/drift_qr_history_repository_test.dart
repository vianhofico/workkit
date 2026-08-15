import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/qr/data/drift_qr_history_repository.dart';
import 'package:workkit/features/qr/domain/qr_history_entry.dart';

void main() {
  late AppDatabase database;
  late DriftQrHistoryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftQrHistoryRepository(database);
  });

  tearDown(() async => database.close());

  test('persists and clears QR history', () async {
    await repository.add(
      QrHistoryEntry(
        id: 'qr-1',
        type: 'generated',
        content: 'WorkKit',
        createdAt: DateTime(2026),
      ),
    );

    final entries = await repository.watchAll().first;
    expect(entries, hasLength(1));
    expect(entries.single.content, 'WorkKit');

    await repository.clear();
    expect(await repository.watchAll().first, isEmpty);
  });
}
