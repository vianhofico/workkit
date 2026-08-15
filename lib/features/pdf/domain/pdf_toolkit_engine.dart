class PdfToolkitOutput {
  const PdfToolkitOutput({required this.paths, required this.tempDirectory});

  final List<String> paths;
  final String tempDirectory;
}

class PdfToolkitException implements Exception {
  const PdfToolkitException(this.message, {this.passwordRequired = false});

  final String message;
  final bool passwordRequired;

  @override
  String toString() => message;
}

abstract interface class PdfToolkitEngine {
  Future<PdfToolkitOutput> imagesToPdf(List<String> imagePaths);
  Future<PdfToolkitOutput> merge(List<String> pdfPaths, {String? password});
  Future<PdfToolkitOutput> split(String pdfPath, int every, {String? password});
  Future<PdfToolkitOutput> deletePages(
    String pdfPath,
    List<int> pages, {
    String? password,
  });
  Future<PdfToolkitOutput> reorderPages(
    String pdfPath,
    List<int> order, {
    String? password,
  });
  Future<PdfToolkitOutput> rotatePages(
    String pdfPath,
    Map<int, int> pages, {
    String? password,
  });
  Future<PdfToolkitOutput> pdfToImages(String pdfPath, {String? password});
  Future<int> pageCount(String pdfPath, {String? password});
  Future<void> cleanup(PdfToolkitOutput output);
}
