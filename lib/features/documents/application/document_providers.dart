import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/features/documents/data/drift_document_repository.dart';
import 'package:workkit/features/documents/domain/document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

final Provider<DocumentRepository> documentRepositoryProvider =
    Provider<DocumentRepository>((ref) {
  return DriftDocumentRepository(ref.watch(appDatabaseProvider));
});

final StreamProvider<List<WorkDocument>> documentsProvider =
    StreamProvider<List<WorkDocument>>((ref) {
  return ref.watch(documentRepositoryProvider).watchAll();
});
