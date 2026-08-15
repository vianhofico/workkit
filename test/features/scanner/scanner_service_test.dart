import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/storage/local_file_service.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';
import 'package:workkit/features/documents/domain/document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/scanner/application/scanner_service.dart';
import 'package:workkit/features/scanner/domain/document_scanner.dart';

void main() {
  late Directory root;
  late _MemoryDocumentRepository repository;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('workkit_scanner_test_');
    repository = _MemoryDocumentRepository();
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('copies scanned pages into managed document storage', () async {
    final File pageOne = File('${root.path}/page-1.jpg');
    final File pageTwo = File('${root.path}/page-2.jpg');
    await pageOne.writeAsBytes(<int>[1, 2, 3]);
    await pageTwo.writeAsBytes(<int>[4, 5, 6]);

    final DocumentLibraryService library = DocumentLibraryService(
      repository: repository,
      picker: const _NoopPicker(),
      storage: LocalFileService.forTesting(Directory('${root.path}/managed')),
    );
    final ScannerService service = ScannerService(
      scanner: _FakeScanner(<String>[pageOne.path, pageTwo.path]),
      library: library,
    );

    final List<WorkDocument>? saved =
        await service.scanAndSave(ScanOutputFormat.images);

    expect(saved, isNotNull);
    expect(saved, hasLength(2));
    expect(repository.documents, hasLength(2));
    expect(await File(saved!.first.path).exists(), isTrue);
    expect(saved.first.type, 'image');
  });

  test('cancelled native scan creates no managed documents', () async {
    final DocumentLibraryService library = DocumentLibraryService(
      repository: repository,
      picker: const _NoopPicker(),
      storage: LocalFileService.forTesting(Directory('${root.path}/managed')),
    );
    final ScannerService service = ScannerService(
      scanner: const _FakeScanner(null),
      library: library,
    );

    final List<WorkDocument>? saved =
        await service.scanAndSave(ScanOutputFormat.pdf);

    expect(saved, isNull);
    expect(repository.documents, isEmpty);
  });
}

class _FakeScanner implements DocumentScanner {
  const _FakeScanner(this.paths);

  final List<String>? paths;

  @override
  Future<DocumentScanResult?> scan({required ScanOutputFormat format}) async {
    if (paths == null) {
      return null;
    }
    return DocumentScanResult(format: format, paths: paths!);
  }
}

class _NoopPicker implements DocumentPicker {
  const _NoopPicker();

  @override
  Future<PickedDocument?> pick() async => null;
}

class _MemoryDocumentRepository implements DocumentRepository {
  final List<WorkDocument> documents = <WorkDocument>[];

  @override
  Future<void> add(WorkDocument document) async => documents.add(document);

  @override
  Future<void> deleteById(String id) async {
    documents.removeWhere((WorkDocument document) => document.id == id);
  }

  @override
  Future<WorkDocument?> getById(String id) async {
    for (final WorkDocument document in documents) {
      if (document.id == id) {
        return document;
      }
    }
    return null;
  }

  @override
  Future<List<WorkDocument>> getRecent({int limit = 10}) async =>
      documents.take(limit).toList(growable: false);

  @override
  Future<void> rename(String id, String name) async {}

  @override
  Future<void> setFavorite(String id, {required bool isFavorite}) async {}

  @override
  Stream<List<WorkDocument>> watchAll() => Stream<List<WorkDocument>>.value(documents);
}
