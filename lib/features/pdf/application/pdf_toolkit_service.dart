import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/pdf/domain/pdf_toolkit_engine.dart';

class PdfToolkitService {
  const PdfToolkitService({required this.engine, required this.library});

  final PdfToolkitEngine engine;
  final DocumentLibraryService library;

  Future<List<WorkDocument>> imagesToPdf(List<WorkDocument> images) => _persist(
        () => engine.imagesToPdf(images.map((item) => item.path).toList()),
        'Images',
      );

  Future<List<WorkDocument>> merge(
    List<WorkDocument> documents, {
    String? password,
  }) => _persist(
        () => engine.merge(
          documents.map((item) => item.path).toList(),
          password: password,
        ),
        'Merged',
      );

  Future<List<WorkDocument>> split(
    WorkDocument document,
    int every, {
    String? password,
  }) => _persist(
        () => engine.split(document.path, every, password: password),
        'Split',
      );

  Future<List<WorkDocument>> deletePages(
    WorkDocument document,
    List<int> pages, {
    String? password,
  }) => _persist(
        () => engine.deletePages(document.path, pages, password: password),
        'Pages removed',
      );

  Future<List<WorkDocument>> reorderPages(
    WorkDocument document,
    List<int> order, {
    String? password,
  }) => _persist(
        () => engine.reorderPages(document.path, order, password: password),
        'Reordered',
      );

  Future<List<WorkDocument>> rotatePages(
    WorkDocument document,
    Map<int, int> pages, {
    String? password,
  }) => _persist(
        () => engine.rotatePages(document.path, pages, password: password),
        'Rotated',
      );

  Future<List<WorkDocument>> pdfToImages(
    WorkDocument document, {
    String? password,
  }) => _persist(
        () => engine.pdfToImages(document.path, password: password),
        'PDF page',
      );

  Future<List<WorkDocument>> _persist(
    Future<PdfToolkitOutput> Function() operation,
    String prefix,
  ) async {
    final PdfToolkitOutput output = await operation();
    final List<WorkDocument> saved = <WorkDocument>[];
    try {
      for (int index = 0; index < output.paths.length; index++) {
        final String path = output.paths[index];
        final String extension = path.toLowerCase().endsWith('.pdf') ? 'pdf' : 'png';
        final String suffix = output.paths.length == 1 ? '' : ' ${index + 1}';
        saved.add(
          await library.importPath(
            sourcePath: path,
            displayName: '$prefix$suffix.$extension',
          ),
        );
      }
      return saved;
    } catch (_) {
      for (final WorkDocument document in saved.reversed) {
        await library.delete(document);
      }
      rethrow;
    } finally {
      await engine.cleanup(output);
    }
  }
}
