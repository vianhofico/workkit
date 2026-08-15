import 'package:workkit/features/documents/domain/work_document.dart';

abstract interface class DocumentRepository {
  Stream<List<WorkDocument>> watchAll();

  Future<List<WorkDocument>> getRecent({int limit = 10});

  Future<WorkDocument?> getById(String id);

  Future<void> add(WorkDocument document);

  Future<void> rename(String id, String name);

  Future<void> deleteById(String id);

  Future<void> setFavorite(String id, {required bool isFavorite});
}
