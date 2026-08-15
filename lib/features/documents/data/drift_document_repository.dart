import 'package:drift/drift.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/documents/domain/document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

class DriftDocumentRepository implements DocumentRepository {
  const DriftDocumentRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<WorkDocument>> watchAll() {
    final query = _database.select(_database.documents)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  @override
  Future<List<WorkDocument>> getRecent({int limit = 10}) async {
    final query = _database.select(_database.documents)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> deleteById(String id) async {
    await (_database.delete(_database.documents)..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> setFavorite(String id, {required bool isFavorite}) async {
    await (_database.update(_database.documents)..where((row) => row.id.equals(id))).write(
      DocumentsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  WorkDocument _toDomain(Document row) => WorkDocument(
        id: row.id,
        name: row.name,
        type: row.type,
        path: row.path,
        thumbnailPath: row.thumbnailPath,
        sizeBytes: row.sizeBytes,
        pageCount: row.pageCount,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isFavorite: row.isFavorite,
      );
}
