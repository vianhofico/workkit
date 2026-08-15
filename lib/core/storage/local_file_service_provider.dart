import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/storage/local_file_service.dart';

final FutureProvider<LocalFileService> localFileServiceProvider =
    FutureProvider<LocalFileService>((ref) {
  return LocalFileService.create();
});
