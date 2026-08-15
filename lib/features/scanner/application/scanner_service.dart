import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/scanner/domain/document_scanner.dart';

class ScannerService {
  const ScannerService({
    required DocumentScanner scanner,
    required DocumentLibraryService library,
  })  : _scanner = scanner,
        _library = library;

  final DocumentScanner _scanner;
  final DocumentLibraryService _library;

  Future<List<WorkDocument>?> scanAndSave(ScanOutputFormat format) async {
    final DocumentScanResult? result = await _scanner.scan(format: format);
    if (result == null) {
      return null;
    }

    final DateTime now = DateTime.now();
    final String stamp = _timestamp(now);
    final List<WorkDocument> saved = <WorkDocument>[];

    try {
      for (int index = 0; index < result.paths.length; index++) {
        final String sourcePath = result.paths[index];
        final String extension = _extensionFromPath(sourcePath, format);
        final String suffix = result.paths.length == 1 ? '' : ' ${index + 1}';
        final WorkDocument document = await _library.importPath(
          sourcePath: sourcePath,
          displayName: 'Scan $stamp$suffix.$extension',
        );
        saved.add(document);
      }
      return saved;
    } catch (_) {
      for (final WorkDocument document in saved.reversed) {
        await _library.delete(document);
      }
      rethrow;
    }
  }

  String _extensionFromPath(String path, ScanOutputFormat format) {
    if (format == ScanOutputFormat.pdf) {
      return 'pdf';
    }
    final String normalized = path.replaceAll('\\', '/');
    final String fileName = normalized.split('/').last;
    final int separator = fileName.lastIndexOf('.');
    if (separator > 0 && separator < fileName.length - 1) {
      final String extension = fileName.substring(separator + 1).toLowerCase();
      if (<String>{'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)) {
        return extension;
      }
    }
    return 'jpg';
  }

  String _timestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}-${two(value.minute)}-${two(value.second)}';
  }
}
