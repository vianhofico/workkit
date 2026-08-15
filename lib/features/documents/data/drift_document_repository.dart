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
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAt),
      ]);

    return query.watch().map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  @override
  Future<List<WorkDocument>> getRecent({int limit = 10}) async {
    final query = _database.select(_database.documents)
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAt),
      ])
      ..limit(limit);

    final List<Document> rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<WorkDocument?> getById(String id) async {
    final query = _database.select(_database.documents)
      ..where((row) => row.id.equals(id));
    final Document? row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> add(WorkDocument document) async {
    await _database.into(_database.documents).insert(
          DocumentsCompanion.insert(
            id: document.id,
            name: document.name,
            type: document.type,
            path: document.path,
            thumbnailPath: Value<String?>(document.thumbnailPath),
            sizeBytes: Value<int>(document.sizeBytes),
            pageCount: Value<int?>(document.pageCount),
            isFavorite: Value<bool>(document.isFavorite),
            createdAt: Value<DateTime>(document.createdAt),
            updatedAt: Value<DateTime>(document.updatedAt),
          ),
        );
  }

  @override
  Future<void> rename(String id, String name) async {
    final String normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('Document name cannot be empty.');
    }

    await (_database.update(_database.documents)
          ..where((row) => row.id.equals(id)))
        .write(
      DocumentsCompanion(
        name: Value<String>(normalizedName),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await (_database.delete(_database.documents)
          ..where((row) => row.id.equals(id)))
        .go();
  }

  @override
  Future<void> setFavorite(String id, {required bool isFavorite}) async {
    await (_database.update(_database.documents)
          ..where((row) => row.id.equals(id)))
        .write(
      DocumentsCompanion(
        isFavorite: Value<bool>(isFavorite),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  WorkDocument _toDomain(Document row) {
    return WorkDocument(
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
}
