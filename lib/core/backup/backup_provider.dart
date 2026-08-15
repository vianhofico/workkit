import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/backup/backup_service.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/core/storage/local_file_service_provider.dart';

final FutureProvider<BackupService> backupServiceProvider =
    FutureProvider<BackupService>((ref) async {
  return BackupService(
    database: ref.watch(appDatabaseProvider),
    storage: await ref.watch(localFileServiceProvider.future),
  );
});
