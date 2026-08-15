import 'package:doc_scan_flutter/doc_scan.dart' as native;
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/scanner/domain/document_scanner.dart';

class NativeDocumentScanner implements DocumentScanner {
  const NativeDocumentScanner();

  @override
  Future<DocumentScanResult?> scan({required ScanOutputFormat format}) async {
    try {
      final List<String>? paths = format == ScanOutputFormat.pdf
          ? await native.DocumentScanner.scan(
              format: native.DocumentScannerFormat.pdf,
            )
          : await native.DocumentScanner.scan();

      if (paths == null) {
        return null;
      }
      final List<String> usablePaths = paths
          .map((String path) => path.trim())
          .where((String path) => path.isNotEmpty)
          .toList(growable: false);
      if (usablePaths.isEmpty) {
        throw const ProcessingFailure('Scanner returned no document pages.');
      }
      return DocumentScanResult(format: format, paths: usablePaths);
    } on native.DocumentScannerException catch (error) {
      throw ProcessingFailure('Document scanning failed.', cause: error);
    }
  }
}
