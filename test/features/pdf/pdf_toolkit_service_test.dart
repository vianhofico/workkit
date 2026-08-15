import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/storage/local_file_service.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';
import 'package:workkit/features/documents/domain/document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/pdf/application/pdf_toolkit_service.dart';
import 'package:workkit/features/pdf/domain/pdf_toolkit_engine.dart';

void main() {
  test('persists generated PDF output then cleans temporary files', () async {
    final Directory root = await Directory.systemTemp.createTemp('workkit_pdf_service_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final File generated = File('${root.path}/generated.pdf');
    await generated.writeAsBytes(<int>[37, 80, 68, 70]);
    final _FakeEngine engine = _FakeEngine(
      PdfToolkitOutput(paths: <String>[generated.path], tempDirectory: root.path),
    );
    final _MemoryRepository repository = _MemoryRepository();
    final DocumentLibraryService library = DocumentLibraryService(
      repository: repository,
      picker: const _NoopPicker(),
      storage: LocalFileService.forTesting(Directory('${root.path}/managed')),
    );
    final PdfToolkitService service = PdfToolkitService(engine: engine, library: library);

    final List<WorkDocument> result = await service.imagesToPdf(<WorkDocument>[
      _document(type: 'image', path: '/a.png'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.type, 'pdf');
    expect(engine.cleaned, isTrue);
    expect(repository.documents, hasLength(1));
  });
}

WorkDocument _document({required String type, required String path}) {
  final DateTime now = DateTime(2026, 8, 16);
  return WorkDocument(
    id: 'input',
    name: 'Input',
    type: type,
    path: path,
    sizeBytes: 1,
    createdAt: now,
    updatedAt: now,
    isFavorite: false,
  );
}

class _FakeEngine implements PdfToolkitEngine {
  _FakeEngine(this.output);
  final PdfToolkitOutput output;
  bool cleaned = false;

  @override
  Future<PdfToolkitOutput> imagesToPdf(List<String> imagePaths) async => output;
  @override
  Future<void> cleanup(PdfToolkitOutput output) async => cleaned = true;
  @override
  Future<PdfToolkitOutput> deletePages(String pdfPath, List<int> pages, {String? password}) => throw UnimplementedError();
  @override
  Future<PdfToolkitOutput> merge(List<String> pdfPaths, {String? password}) => throw UnimplementedError();
  @override
  Future<int> pageCount(String pdfPath, {String? password}) => throw UnimplementedError();
  @override
  Future<PdfToolkitOutput> pdfToImages(String pdfPath, {String? password}) => throw UnimplementedError();
  @override
  Future<PdfToolkitOutput> reorderPages(String pdfPath, List<int> order, {String? password}) => throw UnimplementedError();
  @override
  Future<PdfToolkitOutput> rotatePages(String pdfPath, Map<int, int> pages, {String? password}) => throw UnimplementedError();
  @override
  Future<PdfToolkitOutput> split(String pdfPath, int every, {String? password}) => throw UnimplementedError();
}

class _NoopPicker implements DocumentPicker {
  const _NoopPicker();
  @override
  Future<PickedDocument?> pick() async => null;
}

class _MemoryRepository implements DocumentRepository {
  final List<WorkDocument> documents = <WorkDocument>[];
  @override
  Future<void> add(WorkDocument document) async => documents.add(document);
  @override
  Future<void> deleteById(String id) async => documents.removeWhere((item) => item.id == id);
  @override
  Future<WorkDocument?> getById(String id) async => null;
  @override
  Future<List<WorkDocument>> getRecent({int limit = 10}) async => documents;
  @override
  Future<void> rename(String id, String name) async {}
  @override
  Future<void> setFavorite(String id, {required bool isFavorite}) async {}
  @override
  Stream<List<WorkDocument>> watchAll() => Stream<List<WorkDocument>>.value(documents);
}
