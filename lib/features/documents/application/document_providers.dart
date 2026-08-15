import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/core/storage/local_file_service_provider.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/application/document_share_service.dart';
import 'package:workkit/features/documents/data/drift_document_repository.dart';
import 'package:workkit/features/documents/data/file_picker_document_picker.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';
import 'package:workkit/features/documents/domain/document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

final Provider<DocumentRepository> documentRepositoryProvider =
    Provider<DocumentRepository>((ref) {
  return DriftDocumentRepository(ref.watch(appDatabaseProvider));
});

final Provider<DocumentPicker> documentPickerProvider =
    Provider<DocumentPicker>((ref) {
  return const FilePickerDocumentPicker();
});

final Provider<DocumentShareService> documentShareServiceProvider =
    Provider<DocumentShareService>((ref) {
  return const DocumentShareService();
});

final FutureProvider<DocumentLibraryService> documentLibraryServiceProvider =
    FutureProvider<DocumentLibraryService>((ref) async {
  return DocumentLibraryService(
    repository: ref.watch(documentRepositoryProvider),
    picker: ref.watch(documentPickerProvider),
    storage: await ref.watch(localFileServiceProvider.future),
  );
});

final StreamProvider<List<WorkDocument>> documentsProvider =
    StreamProvider<List<WorkDocument>>((ref) {
  return ref.watch(documentRepositoryProvider).watchAll();
});
