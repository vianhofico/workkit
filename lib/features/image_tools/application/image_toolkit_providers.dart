import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/recovery/recovery_provider.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/image_tools/application/image_toolkit_service.dart';
import 'package:workkit/features/image_tools/data/dart_image_toolkit_engine.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

final Provider<ImageToolkitEngine> imageToolkitEngineProvider =
    Provider<ImageToolkitEngine>((ref) => const DartImageToolkitEngine());

final FutureProvider<ImageToolkitService> imageToolkitServiceProvider =
    FutureProvider<ImageToolkitService>((ref) async {
  return ImageToolkitService(
    engine: ref.watch(imageToolkitEngineProvider),
    library: await ref.watch(documentLibraryServiceProvider.future),
    jobs: ref.watch(toolJobTrackerProvider),
  );
});
