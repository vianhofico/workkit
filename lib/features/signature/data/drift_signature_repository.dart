import 'package:drift/drift.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/signature/domain/saved_signature.dart';
import 'package:workkit/features/signature/domain/signature_repository.dart';

class DriftSignatureRepository implements SignatureRepository {
  const DriftSignatureRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<SavedSignature>> watchAll() {
    final query = database.select(database.signatures)
      ..orderBy(<OrderClauseGenerator<$SignaturesTable>>[
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => SavedSignature(
                  id: row.id,
                  name: row.name,
                  path: row.path,
                  createdAt: row.createdAt,
                  isDefault: row.isDefault,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<void> save(SavedSignature signature) {
    return database.into(database.signatures).insert(
          SignaturesCompanion.insert(
            id: signature.id,
            name: signature.name,
            path: signature.path,
            isDefault: Value<bool>(signature.isDefault),
            createdAt: Value<DateTime>(signature.createdAt),
          ),
        );
  }

  @override
  Future<void> deleteById(String id) {
    return (database.delete(database.signatures)..where((row) => row.id.equals(id))).go();
  }
}
