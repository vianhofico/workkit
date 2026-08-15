import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/recovery/recovery_provider.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/pdf/application/pdf_toolkit_service.dart';
import 'package:workkit/features/pdf/data/pdf_manipulator_toolkit_engine.dart';
import 'package:workkit/features/pdf/domain/pdf_toolkit_engine.dart';

final Provider<PdfToolkitEngine> pdfToolkitEngineProvider =
    Provider<PdfToolkitEngine>((ref) => const PdfManipulatorToolkitEngine());

final FutureProvider<PdfToolkitService> pdfToolkitServiceProvider =
    FutureProvider<PdfToolkitService>((ref) async {
  return PdfToolkitService(
    engine: ref.watch(pdfToolkitEngineProvider),
    library: await ref.watch(documentLibraryServiceProvider.future),
    jobs: ref.watch(toolJobTrackerProvider),
  );
});
