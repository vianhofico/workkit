import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/ocr/data/drift_ocr_repository.dart';
import 'package:workkit/features/ocr/domain/ocr_repository.dart';

void main() {
  late AppDatabase database;
  late DriftOcrRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftOcrRepository(database);
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'doc-1',
            name: 'fixture.png',
            type: 'image',
            path: '/fixture.png',
          ),
        );
  });

  tearDown(() async => database.close());

  test('saves and replaces OCR text for a document', () async {
    await repository.save(
      documentId: 'doc-1',
      text: 'first',
      language: 'latin',
    );
    await repository.save(
      documentId: 'doc-1',
      text: 'edited',
      language: 'latin',
    );

    final StoredOcrText? value = await repository.load('doc-1');
    expect(value, isNotNull);
    expect(value!.text, 'edited');
    expect((await database.select(database.ocrResults).get()).length, 1);
  });
}
