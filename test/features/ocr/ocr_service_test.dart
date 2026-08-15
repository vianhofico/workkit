import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/ocr/application/ocr_service.dart';
import 'package:workkit/features/ocr/domain/ocr_engine.dart';
import 'package:workkit/features/ocr/domain/ocr_repository.dart';

void main() {
  test('recognizes and persists an image document', () async {
    final _MemoryOcrRepository repository = _MemoryOcrRepository();
    final OcrService service = OcrService(
      engine: const _FakeOcrEngine(<String, String>{
        '/invoice.jpg': 'Invoice\nTotal 250.000 VND\nmail@example.com',
      }),
      pdfRenderer: const _FakeRenderer(<String>[]),
      repository: repository,
    );

    final OcrDocumentResult result = await service.extract(
      _document(type: 'image', path: '/invoice.jpg'),
    );

    expect(result.text, contains('Invoice'));
    expect(result.entities.emails, contains('mail@example.com'));
    expect(repository.value?.text, result.text);
  });

  test('aggregates rendered PDF pages and cleans temporary pages', () async {
    final _MemoryOcrRepository repository = _MemoryOcrRepository();
    final _FakeRenderer renderer = _FakeRenderer(<String>['/tmp/p1.png', '/tmp/p2.png']);
    final OcrService service = OcrService(
      engine: const _FakeOcrEngine(<String, String>{
        '/tmp/p1.png': 'First page',
        '/tmp/p2.png': 'Second page',
      }),
      pdfRenderer: renderer,
      repository: repository,
    );

    final OcrDocumentResult result = await service.extract(
      _document(type: 'pdf', path: '/document.pdf'),
    );

    expect(result.text, contains('--- Page 1 ---'));
    expect(result.text, contains('--- Page 2 ---'));
    expect(renderer.cleaned, isTrue);
  });
}

WorkDocument _document({required String type, required String path}) {
  final DateTime now = DateTime(2026, 8, 16);
  return WorkDocument(
    id: 'doc-1',
    name: 'Fixture',
    type: type,
    path: path,
    sizeBytes: 1,
    createdAt: now,
    updatedAt: now,
    isFavorite: false,
  );
}

class _FakeOcrEngine implements OcrEngine {
  const _FakeOcrEngine(this.values);

  final Map<String, String> values;

  @override
  Future<String> recognizeImage(String imagePath) async => values[imagePath] ?? '';
}

class _FakeRenderer implements PdfOcrPageRenderer {
  const _FakeRenderer(this.paths);

  final List<String> paths;
  static bool _cleaned = false;

  bool get cleaned => _cleaned;

  @override
  Future<void> cleanup(List<String> renderedPaths) async {
    _cleaned = true;
  }

  @override
  Future<List<String>> renderPdf(String pdfPath) async {
    _cleaned = false;
    return paths;
  }
}

class _MemoryOcrRepository implements OcrRepository {
  StoredOcrText? value;

  @override
  Future<StoredOcrText?> load(String documentId) async => value;

  @override
  Future<void> save({
    required String documentId,
    required String text,
    String? language,
  }) async {
    value = StoredOcrText(text: text, language: language);
  }
}
