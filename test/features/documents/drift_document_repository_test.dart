import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/documents/data/drift_document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

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

  test('returns recent documents newest first', () async {
    final DateTime older = DateTime(2026, 8, 10);
    final DateTime newer = DateTime(2026, 8, 11);

    await database.batch((Batch batch) {
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

    final List<WorkDocument> recent = await repository.getRecent();

    expect(recent.map((WorkDocument document) => document.id), <String>[
      'newer',
      'older',
    ]);
  });

  test('adds, reads and renames a document', () async {
    final DateTime now = DateTime(2026, 8, 16);
    const String id = 'doc-1';
    await repository.add(
      WorkDocument(
        id: id,
        name: 'Invoice.pdf',
        type: 'pdf',
        path: '/invoice.pdf',
        sizeBytes: 42,
        createdAt: now,
        updatedAt: now,
        isFavorite: false,
      ),
    );

    await repository.rename(id, 'Invoice August.pdf');

    final WorkDocument? document = await repository.getById(id);
    expect(document, isNotNull);
    expect(document!.name, 'Invoice August.pdf');
    expect(document.sizeBytes, 42);
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

    final List<WorkDocument> recent = await repository.getRecent();
    expect(recent.single.isFavorite, isTrue);
  });

  test('deletes metadata by id', () async {
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'doc-1',
            name: 'Invoice.pdf',
            type: 'pdf',
            path: '/invoice.pdf',
          ),
        );

    await repository.deleteById('doc-1');

    expect(await repository.getById('doc-1'), isNull);
  });
}
