import 'package:drift/drift.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/qr/domain/qr_history_entry.dart';
import 'package:workkit/features/qr/domain/qr_history_repository.dart';

class DriftQrHistoryRepository implements QrHistoryRepository {
  const DriftQrHistoryRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<QrHistoryEntry>> watchAll() {
    final query = database.select(database.qrHistory)
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => QrHistoryEntry(
                  id: row.id,
                  type: row.type,
                  content: row.content,
                  createdAt: row.createdAt,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<void> add(QrHistoryEntry entry) {
    return database.into(database.qrHistory).insert(
          QrHistoryCompanion.insert(
            id: entry.id,
            type: entry.type,
            content: entry.content,
            createdAt: Value<DateTime>(entry.createdAt),
          ),
        );
  }

  @override
  Future<void> clear() => database.delete(database.qrHistory).go();
}
