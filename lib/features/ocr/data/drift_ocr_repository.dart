import 'package:drift/drift.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/features/ocr/domain/ocr_repository.dart';

class DriftOcrRepository implements OcrRepository {
  const DriftOcrRepository(this._database);

  final AppDatabase _database;

  @override
  Future<StoredOcrText?> load(String documentId) async {
    final query = _database.select(_database.ocrResults)
      ..where((OcrResults row) => row.documentId.equals(documentId))
      ..orderBy(<OrderClauseGenerator<OcrResults>>[
        (OcrResults row) => OrderingTerm.desc(row.createdAt),
      ])
      ..limit(1);
    final result = await query.getSingleOrNull();
    if (result == null) {
      return null;
    }
    return StoredOcrText(text: result.textContent, language: result.language);
  }

  @override
  Future<void> save({
    required String documentId,
    required String text,
    String? language,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(_database.ocrResults)
            ..where((OcrResults row) => row.documentId.equals(documentId)))
          .go();
      await _database.into(_database.ocrResults).insert(
            OcrResultsCompanion.insert(
              id: 'ocr-$documentId-${DateTime.now().microsecondsSinceEpoch}',
              documentId: documentId,
              textContent: text,
              language: Value<String?>(language),
            ),
          );
    });
  }
}
