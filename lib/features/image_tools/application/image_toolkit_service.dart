import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

class ImageToolkitService {
  const ImageToolkitService({required this.engine, required this.library});

  final ImageToolkitEngine engine;
  final DocumentLibraryService library;

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
    final ImageToolkitOutput output = await operation();
    try {
      return await library.importPath(
        sourcePath: output.path,
        displayName: '$prefix ${_stem(source.name)}.${output.format.extension}',
      );
    } finally {
      await engine.cleanup(output);
    }
  }

  String _stem(String name) {
    final int separator = name.lastIndexOf('.');
    return separator <= 0 ? name : name.substring(0, separator);
  }
}
