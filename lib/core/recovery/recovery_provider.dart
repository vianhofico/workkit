import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/core/recovery/tool_job_tracker.dart';
import 'package:workkit/core/storage/local_file_service_provider.dart';

class AppRecoverySummary {
  const AppRecoverySummary({
    required this.interruptedJobs,
    required this.recoveredBytes,
  });

  final int interruptedJobs;
  final int recoveredBytes;
}

final Provider<ToolJobTracker> toolJobTrackerProvider =
    Provider<ToolJobTracker>((ref) {
  return ToolJobTracker(ref.watch(appDatabaseProvider));
});

final FutureProvider<AppRecoverySummary> appRecoveryProvider =
    FutureProvider<AppRecoverySummary>((ref) async {
  final int interrupted =
      await ref.watch(toolJobTrackerProvider).recoverInterrupted();
  final int recoveredBytes = await (await ref.watch(
    localFileServiceProvider.future,
  ))
      .recoverAbandonedFiles(includeRecent: true);
  return AppRecoverySummary(
    interruptedJobs: interrupted,
    recoveredBytes: recoveredBytes,
  );
});
