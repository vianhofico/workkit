import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/signature/data/drift_signature_repository.dart';
import 'package:workkit/features/signature/domain/saved_signature.dart';

void main() {
  late AppDatabase database;
  late DriftSignatureRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSignatureRepository(database);
  });

  tearDown(() async => database.close());

  test('stores and deletes saved signatures', () async {
    final SavedSignature signature = SavedSignature(
      id: 'sig-1',
      name: 'Primary',
      path: '/tmp/signature.png',
      createdAt: DateTime(2026),
    );
    await repository.save(signature);

    final List<SavedSignature> saved = await repository.watchAll().first;
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Primary');

    await repository.deleteById(signature.id);
    expect(await repository.watchAll().first, isEmpty);
  });
}
