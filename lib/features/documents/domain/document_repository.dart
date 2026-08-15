import 'package:workkit/features/documents/domain/work_document.dart';

abstract interface class DocumentRepository {
  Stream<List<WorkDocument>> watchAll();
  Future<List<WorkDocument>> getRecent({int limit = 10});
  Future<void> deleteById(String id);
  Future<void> setFavorite(String id, {required bool isFavorite});
}
