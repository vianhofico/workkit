import 'package:workkit/core/recovery/tool_job_tracker.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/pdf/domain/pdf_toolkit_engine.dart';

class PdfToolkitService {
  const PdfToolkitService({
    required this.engine,
    required this.library,
    this.jobs,
  });

  final PdfToolkitEngine engine;
  final DocumentLibraryService library;
  final ToolJobTracker? jobs;

  Future<List<WorkDocument>> imagesToPdf(List<WorkDocument> images) => _persist(
        () => engine.imagesToPdf(images.map((item) => item.path).toList()),
        'Images',
        inputPath: images.isEmpty ? null : images.first.path,
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
        inputPath: documents.isEmpty ? null : documents.first.path,
      );

  Future<List<WorkDocument>> split(
    WorkDocument document,
    int every, {
    String? password,
  }) => _persist(
        () => engine.split(document.path, every, password: password),
        'Split',
        inputPath: document.path,
      );

  Future<List<WorkDocument>> deletePages(
    WorkDocument document,
    List<int> pages, {
    String? password,
  }) => _persist(
        () => engine.deletePages(document.path, pages, password: password),
        'Pages removed',
        inputPath: document.path,
      );

  Future<List<WorkDocument>> reorderPages(
    WorkDocument document,
    List<int> order, {
    String? password,
  }) => _persist(
        () => engine.reorderPages(document.path, order, password: password),
        'Reordered',
        inputPath: document.path,
      );

  Future<List<WorkDocument>> rotatePages(
    WorkDocument document,
    Map<int, int> pages, {
    String? password,
  }) => _persist(
        () => engine.rotatePages(document.path, pages, password: password),
        'Rotated',
        inputPath: document.path,
      );

  Future<List<WorkDocument>> pdfToImages(
    WorkDocument document, {
    String? password,
  }) => _persist(
        () => engine.pdfToImages(document.path, password: password),
        'PDF page',
        inputPath: document.path,
      );

  Future<List<WorkDocument>> _persist(
    Future<PdfToolkitOutput> Function() operation,
    String prefix, {
    String? inputPath,
  }) async {
    final String? jobId = await _startJob(prefix, inputPath);
    PdfToolkitOutput? output;
    final List<WorkDocument> saved = <WorkDocument>[];
    try {
      output = await operation();
      for (int index = 0; index < output.paths.length; index++) {
        final String path = output.paths[index];
        final String extension =
            path.toLowerCase().endsWith('.pdf') ? 'pdf' : 'png';
        final String suffix = output.paths.length == 1 ? '' : ' ${index + 1}';
        saved.add(
          await library.importPath(
            sourcePath: path,
            displayName: '$prefix$suffix.$extension',
          ),
        );
      }
      await _completeJob(
        jobId,
        saved.isEmpty ? null : saved.first.path,
      );
      return saved;
    } catch (_) {
      for (final WorkDocument document in saved.reversed) {
        await library.delete(document);
      }
      await _failJob(jobId);
      rethrow;
    } finally {
      if (output != null) {
        await engine.cleanup(output);
      }
    }
  }

  Future<String?> _startJob(String prefix, String? inputPath) async {
    try {
      return await jobs?.start(
        tool: 'pdf:${prefix.toLowerCase().replaceAll(' ', '-')}',
        inputPath: inputPath,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _completeJob(String? id, String? outputPath) async {
    if (id == null) return;
    try {
      await jobs?.complete(id, outputPath: outputPath);
    } catch (_) {}
  }

  Future<void> _failJob(String? id) async {
    if (id == null) return;
    try {
      await jobs?.fail(id);
    } catch (_) {}
  }
}
