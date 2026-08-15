enum ScanOutputFormat { images, pdf }

class DocumentScanResult {
  const DocumentScanResult({required this.format, required this.paths});

  final ScanOutputFormat format;
  final List<String> paths;

  int get pageCount => paths.length;
}

abstract interface class DocumentScanner {
  Future<DocumentScanResult?> scan({required ScanOutputFormat format});
}
