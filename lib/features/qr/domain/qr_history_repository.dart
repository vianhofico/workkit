import 'package:workkit/features/qr/domain/qr_history_entry.dart';

abstract interface class QrHistoryRepository {
  Stream<List<QrHistoryEntry>> watchAll();
  Future<void> add(QrHistoryEntry entry);
  Future<void> clear();
}
