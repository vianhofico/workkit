class PdfPageGeometry {
  const PdfPageGeometry({required this.width, required this.height});

  final double width;
  final double height;
}

class PdfSignaturePlacement {
  const PdfSignaturePlacement({
    required this.page,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotationDegrees = 0,
  });

  final int page;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotationDegrees;
}

class PdfSignatureOutput {
  const PdfSignatureOutput({required this.path, required this.tempDirectory});

  final String path;
  final String tempDirectory;
}

class SignaturePdfException implements Exception {
  const SignaturePdfException(this.message, {this.passwordRequired = false});

  final String message;
  final bool passwordRequired;

  @override
  String toString() => message;
}

abstract interface class SignaturePdfEngine {
  Future<PdfPageGeometry> pageGeometry(
    String pdfPath,
    int page, {
    String? password,
  });

  Future<PdfSignatureOutput> placeSignature(
    String pdfPath,
    String signaturePath,
    PdfSignaturePlacement placement, {
    String? password,
  });

  Future<void> cleanup(PdfSignatureOutput output);
}
