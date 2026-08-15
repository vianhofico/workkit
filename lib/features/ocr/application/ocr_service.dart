import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/ocr/domain/ocr_engine.dart';
import 'package:workkit/features/ocr/domain/ocr_repository.dart';
import 'package:workkit/features/ocr/domain/smart_extractor.dart';

class OcrDocumentResult {
  const OcrDocumentResult({required this.text, required this.entities});

  final String text;
  final SmartEntities entities;
}

class OcrService {
  const OcrService({
    required this.engine,
    required this.pdfRenderer,
    required this.repository,
    this.extractor = const SmartExtractor(),
  });

  final OcrEngine engine;
  final PdfOcrPageRenderer pdfRenderer;
  final OcrRepository repository;
  final SmartExtractor extractor;

  Future<OcrDocumentResult> extract(WorkDocument document) async {
    final bool isPdf = document.type == 'pdf';
    if (!isPdf && document.type != 'image') {
      throw const ProcessingFailure('OCR supports images and PDF documents.');
    }

    final List<String> paths =
        isPdf ? await pdfRenderer.renderPdf(document.path) : <String>[document.path];
    try {
      final List<String> pages = <String>[];
      for (final String path in paths) {
        pages.add(await engine.recognizeImage(path));
      }
      final String text = pages
          .asMap()
          .entries
          .map((entry) => pages.length == 1
              ? entry.value
              : '--- Page ${entry.key + 1} ---\n${entry.value}')
          .join('\n\n')
          .trim();
      await repository.save(
        documentId: document.id,
        text: text,
        language: 'latin',
      );
      return OcrDocumentResult(text: text, entities: extractor.extract(text));
    } finally {
      if (isPdf) {
        await pdfRenderer.cleanup(paths);
      }
    }
  }

  Future<OcrDocumentResult?> load(String documentId) async {
    final StoredOcrText? stored = await repository.load(documentId);
    if (stored == null) {
      return null;
    }
    return OcrDocumentResult(
      text: stored.text,
      entities: extractor.extract(stored.text),
    );
  }

  Future<OcrDocumentResult> saveEdited(String documentId, String text) async {
    final String normalized = text.trim();
    await repository.save(
      documentId: documentId,
      text: normalized,
      language: 'latin',
    );
    return OcrDocumentResult(
      text: normalized,
      entities: extractor.extract(normalized),
    );
  }
}
