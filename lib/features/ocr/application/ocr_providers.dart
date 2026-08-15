import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/core/recovery/recovery_provider.dart';
import 'package:workkit/features/ocr/application/ocr_service.dart';
import 'package:workkit/features/ocr/data/drift_ocr_repository.dart';
import 'package:workkit/features/ocr/data/mlkit_ocr_engine.dart';
import 'package:workkit/features/ocr/data/pdf_manipulator_ocr_renderer.dart';
import 'package:workkit/features/ocr/domain/ocr_engine.dart';
import 'package:workkit/features/ocr/domain/ocr_repository.dart';

final Provider<OcrEngine> ocrEngineProvider =
    Provider<OcrEngine>((ref) => const MlKitOcrEngine());

final Provider<PdfOcrPageRenderer> pdfOcrPageRendererProvider =
    Provider<PdfOcrPageRenderer>((ref) => const PdfManipulatorOcrRenderer());

final Provider<OcrRepository> ocrRepositoryProvider =
    Provider<OcrRepository>((ref) {
  return DriftOcrRepository(ref.watch(appDatabaseProvider));
});

final Provider<OcrService> ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(
    engine: ref.watch(ocrEngineProvider),
    pdfRenderer: ref.watch(pdfOcrPageRendererProvider),
    repository: ref.watch(ocrRepositoryProvider),
    jobs: ref.watch(toolJobTrackerProvider),
  );
});
