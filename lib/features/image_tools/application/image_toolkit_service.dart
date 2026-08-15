import 'package:workkit/core/recovery/tool_job_tracker.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

class ImageToolkitService {
  const ImageToolkitService({
    required this.engine,
    required this.library,
    this.jobs,
  });

  final ImageToolkitEngine engine;
  final DocumentLibraryService library;
  final ToolJobTracker? jobs;

  Future<WorkDocument> compress(WorkDocument document, {int quality = 80}) {
    return _persist(
      document,
      () => engine.compress(document.path, quality: quality),
      'Compressed',
    );
  }

  Future<WorkDocument> resize(
    WorkDocument document, {
    int? width,
    int? height,
    bool maintainAspect = true,
  }) {
    return _persist(
      document,
      () => engine.resize(
        document.path,
        width: width,
        height: height,
        maintainAspect: maintainAspect,
      ),
      'Resized',
    );
  }

  Future<WorkDocument> crop(
    WorkDocument document, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    return _persist(
      document,
      () => engine.crop(
        document.path,
        x: x,
        y: y,
        width: width,
        height: height,
      ),
      'Cropped',
    );
  }

  Future<WorkDocument> convert(
    WorkDocument document,
    ImageOutputFormat format, {
    int quality = 90,
  }) {
    return _persist(
      document,
      () => engine.convert(document.path, format, quality: quality),
      'Converted',
    );
  }

  Future<WorkDocument> removeMetadata(WorkDocument document) {
    return _persist(
      document,
      () => engine.removeMetadata(document.path),
      'Private',
    );
  }

  Future<WorkDocument> _persist(
    WorkDocument source,
    Future<ImageToolkitOutput> Function() operation,
    String prefix,
  ) async {
    if (source.type != 'image') {
      throw const FormatException('Choose an image file.');
    }
    final String? jobId = await _startJob('image:${prefix.toLowerCase()}', source.path);
    ImageToolkitOutput? output;
    try {
      output = await operation();
      final WorkDocument saved = await library.importPath(
        sourcePath: output.path,
        displayName: '$prefix ${_stem(source.name)}.${output.format.extension}',
      );
      await _completeJob(jobId, saved.path);
      return saved;
    } catch (_) {
      await _failJob(jobId);
      rethrow;
    } finally {
      if (output != null) {
        await engine.cleanup(output);
      }
    }
  }

  Future<String?> _startJob(String tool, String inputPath) async {
    try {
      return await jobs?.start(tool: tool, inputPath: inputPath);
    } catch (_) {
      return null;
    }
  }

  Future<void> _completeJob(String? id, String outputPath) async {
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

  String _stem(String name) {
    final int separator = name.lastIndexOf('.');
    return separator <= 0 ? name : name.substring(0, separator);
  }
}
