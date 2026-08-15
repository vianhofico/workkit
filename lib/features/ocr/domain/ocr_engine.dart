abstract interface class OcrEngine {
  Future<String> recognizeImage(String imagePath);
}

abstract interface class PdfOcrPageRenderer {
  Future<List<String>> renderPdf(String pdfPath);

  Future<void> cleanup(List<String> renderedPaths);
}
