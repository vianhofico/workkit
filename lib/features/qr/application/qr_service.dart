import 'dart:math';

import 'package:workkit/features/qr/domain/qr_history_entry.dart';
import 'package:workkit/features/qr/domain/qr_history_repository.dart';

class QrService {
  const QrService(this.repository);

  final QrHistoryRepository repository;

  Future<QrHistoryEntry> recordScan(String content, {String format = 'qr'}) {
    return _record('scan:$format', content);
  }

  Future<QrHistoryEntry> recordGenerated(String content) {
    return _record('generated', content);
  }

  Future<void> clearHistory() => repository.clear();

  Future<QrHistoryEntry> _record(String type, String content) async {
    final String normalized = content.trim();
    if (normalized.isEmpty) {
      throw const FormatException('QR content cannot be empty.');
    }
    final DateTime now = DateTime.now();
    final QrHistoryEntry entry = QrHistoryEntry(
      id: '${now.microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(0x7fffffff).toRadixString(36)}',
      type: type,
      content: normalized,
      createdAt: now,
    );
    await repository.add(entry);
    return entry;
  }
}
