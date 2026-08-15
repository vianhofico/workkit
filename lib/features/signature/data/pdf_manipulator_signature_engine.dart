import 'dart:io';

import 'package:image/image.dart' as image_lib;
import 'package:pdf_manipulator/io.dart' as pdf_io;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:workkit/features/signature/domain/signature_pdf_engine.dart';

class PdfManipulatorSignatureEngine implements SignaturePdfEngine {
  const PdfManipulatorSignatureEngine();

  @override
  Future<PdfPageGeometry> pageGeometry(
    String pdfPath,
    int page, {
    String? password,
  }) => _guard(() async {
        final Pdf pdf = Pdf();
        PdfDoc? document;
        try {
          document = await pdf.open(
            pdf_io.FileSource(File(pdfPath)),
            password: _password(password),
          );
          _validatePage(page, document.pageCount);
          final PdfPageInfo info = document.pages[page];
          return PdfPageGeometry(width: info.width, height: info.height);
        } finally {
          await document?.dispose();
          await pdf.dispose();
        }
      });

  @override
  Future<PdfSignatureOutput> placeSignature(
    String pdfPath,
    String signaturePath,
    PdfSignaturePlacement placement, {
    String? password,
  }) => _guard(() async {
        if (placement.width <= 0 || placement.height <= 0) {
          throw const SignaturePdfException('Signature size must be greater than zero.');
        }
        final Directory directory = await Directory.systemTemp.createTemp('workkit_signature_pdf_');
        final Pdf pdf = Pdf();
        PdfDoc? document;
        try {
          final String prepared = await _preparePdf(pdf, pdfPath, password, directory);
          document = await pdf.open(pdf_io.FileSource(File(prepared)));
          _validatePage(placement.page, document.pageCount);
          final PdfPageInfo info = document.pages[placement.page];
          if (placement.x < 0 ||
              placement.y < 0 ||
              placement.x + placement.width > info.width ||
              placement.y + placement.height > info.height) {
            throw const SignaturePdfException('Signature placement must stay inside the selected page.');
          }

          final String stampPath = await _rotatedStamp(signaturePath, placement.rotationDegrees, directory);
          final String outputPath = '${directory.path}/signed.pdf';
          final pdf_io.FileSink sink = await pdf_io.FileSink.create(File(outputPath));
          try {
            await pdf.addImageStamp(
              pdf_io.FileSource(File(prepared)),
              sink,
              page: placement.page,
              imageData: pdf_io.FileSource(File(stampPath)),
              rect: PdfRect(
                x: placement.x,
                y: placement.y,
                width: placement.width,
                height: placement.height,
              ),
            );
          } finally {
            await sink.close();
          }
          return PdfSignatureOutput(path: outputPath, tempDirectory: directory.path);
        } catch (_) {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
          rethrow;
        } finally {
          await document?.dispose();
          await pdf.dispose();
        }
      });

  Future<String> _rotatedStamp(
    String sourcePath,
    double degrees,
    Directory directory,
  ) async {
    final double normalized = degrees % 360;
    if (normalized == 0) {
      return sourcePath;
    }
    final image_lib.Image? source = image_lib.decodeImage(await File(sourcePath).readAsBytes());
    if (source == null) {
      throw const SignaturePdfException('Saved signature image is invalid.');
    }
    final image_lib.Image rotated = image_lib.copyRotate(source, angle: normalized);
    final String output = '${directory.path}/signature-rotated.png';
    await File(output).writeAsBytes(image_lib.encodePng(rotated), flush: true);
    return output;
  }

  Future<String> _preparePdf(
    Pdf pdf,
    String path,
    String? password,
    Directory directory,
  ) async {
    final pdf_io.FileSource source = pdf_io.FileSource(File(path));
    PdfDoc? document;
    try {
      document = await pdf.open(source, password: _password(password));
      if (!document.isEncrypted) {
        return path;
      }
    } finally {
      await document?.dispose();
    }

    final String? normalizedPassword = _password(password);
    if (normalizedPassword == null) {
      throw const SignaturePdfException(
        'This PDF is password protected. Enter its password and try again.',
        passwordRequired: true,
      );
    }
    final String decrypted = '${directory.path}/decrypted.pdf';
    final pdf_io.FileSink sink = await pdf_io.FileSink.create(File(decrypted));
    try {
      await pdf.decrypt(source, sink, password: normalizedPassword);
    } finally {
      await sink.close();
    }
    return decrypted;
  }

  void _validatePage(int page, int pageCount) {
    if (page < 0 || page >= pageCount) {
      throw SignaturePdfException('Page must be between 1 and $pageCount.');
    }
  }

  String? _password(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PdfPasswordRequired {
      throw const SignaturePdfException(
        'This PDF is password protected. Enter its password and try again.',
        passwordRequired: true,
      );
    } on PdfWrongPassword {
      throw const SignaturePdfException('The PDF password is incorrect.', passwordRequired: true);
    } on PdfError catch (error) {
      throw SignaturePdfException(error.message);
    }
  }

  @override
  Future<void> cleanup(PdfSignatureOutput output) async {
    final Directory directory = Directory(output.tempDirectory);
    if (await directory.exists() && directory.path.contains('workkit_signature_pdf_')) {
      await directory.delete(recursive: true);
    }
  }
}
