import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/documents/data/drift_document_repository.dart';

void main() {
  late AppDatabase database;
  late DriftDocumentRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDocumentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('updates favorite state', () async {
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'doc-1',
            name: 'Invoice.pdf',
            type: 'pdf',
            path: '/invoice.pdf',
          ),
        );

    await repository.setFavorite('doc-1', isFavorite: true);
    final recent = await repository.getRecent();
    expect(recent.single.isFavorite, isTrue);
  });

  test('returns recent documents newest first', () async {
    final older = DateTime(2026, 8, 10);
    final newer = DateTime(2026, 8, 11);

    await database.batch((batch) {
      batch.insertAll(database.documents, <DocumentsCompanion>[
        DocumentsCompanion.insert(
          id: 'older',
          name: 'Older.pdf',
          type: 'pdf',
          path: '/older.pdf',
          updatedAt: Value<DateTime>(older),
          createdAt: Value<DateTime>(older),
        ),
        DocumentsCompanion.insert(
          id: 'newer',
          name: 'Newer.pdf',
          type: 'pdf',
          path: '/newer.pdf',
          updatedAt: Value<DateTime>(newer),
          createdAt: Value<DateTime>(newer),
        ),
      ]);
    });

    final recent = await repository.getRecent();
    expect(recent.map((document) => document.id), <String>['newer', 'older']);
  });
}
