import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/features/qr/application/qr_service.dart';
import 'package:workkit/features/qr/data/drift_qr_history_repository.dart';
import 'package:workkit/features/qr/domain/qr_history_entry.dart';
import 'package:workkit/features/qr/domain/qr_history_repository.dart';

final Provider<QrHistoryRepository> qrHistoryRepositoryProvider =
    Provider<QrHistoryRepository>((ref) {
  return DriftQrHistoryRepository(ref.watch(appDatabaseProvider));
});

final Provider<QrService> qrServiceProvider = Provider<QrService>((ref) {
  return QrService(ref.watch(qrHistoryRepositoryProvider));
});

final StreamProvider<List<QrHistoryEntry>> qrHistoryProvider =
    StreamProvider<List<QrHistoryEntry>>((ref) {
  return ref.watch(qrHistoryRepositoryProvider).watchAll();
});
