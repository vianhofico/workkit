import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('persists a document record', () async {
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'doc-1',
            name: 'Invoice.pdf',
            type: 'pdf',
            path: '/documents/invoice.pdf',
          ),
        );

    final Document saved = await database.select(database.documents).getSingle();
    expect(saved.id, 'doc-1');
    expect(saved.name, 'Invoice.pdf');
    expect(saved.isFavorite, isFalse);
  });
}
