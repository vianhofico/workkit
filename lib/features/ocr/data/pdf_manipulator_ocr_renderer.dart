import 'dart:io';

import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/ocr/domain/ocr_engine.dart';

class PdfManipulatorOcrRenderer implements PdfOcrPageRenderer {
  const PdfManipulatorOcrRenderer();

  @override
  Future<List<String>> renderPdf(String pdfPath) async {
    final Directory directory =
        await Directory.systemTemp.createTemp('workkit_ocr_pdf_');
    final Pdf pdf = Pdf();
    PdfDoc? document;
    final List<String> paths = <String>[];

    try {
      document = await pdf.open(FileSource(File(pdfPath)));
      int index = 0;
      await for (final RenderedPage page in document.render(
        pages: const PdfPages.all(),
        size: const PdfRenderSize(maxWidth: 2000, maxHeight: 2800),
      )) {
        final File output = File('${directory.path}/page-${index + 1}.png');
        await output.writeAsBytes(page.data, flush: true);
        paths.add(output.path);
        index++;
      }
      if (paths.isEmpty) {
        throw const ProcessingFailure('The PDF contains no renderable pages.');
      }
      return paths;
    } on AppFailure {
      await directory.delete(recursive: true);
      rethrow;
    } catch (error) {
      await directory.delete(recursive: true);
      throw ProcessingFailure('Unable to prepare PDF pages for OCR.', cause: error);
    } finally {
      await document?.dispose();
      await pdf.dispose();
    }
  }

  @override
  Future<void> cleanup(List<String> renderedPaths) async {
    if (renderedPaths.isEmpty) {
      return;
    }
    final Directory directory = File(renderedPaths.first).parent;
    if (await directory.exists() && directory.path.contains('workkit_ocr_pdf_')) {
      await directory.delete(recursive: true);
      return;
    }
    for (final String path in renderedPaths) {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
