import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/features/qr/application/qr_service.dart';
import 'package:workkit/features/qr/domain/qr_history_entry.dart';
import 'package:workkit/features/qr/domain/qr_history_repository.dart';

void main() {
  test('records generated and scanned QR content', () async {
    final _MemoryQrRepository repository = _MemoryQrRepository();
    final QrService service = QrService(repository);

    await service.recordGenerated('https://workkit.local');
    await service.recordScan('hello', format: 'qrCode');

    expect(repository.items, hasLength(2));
    expect(repository.items.first.type, 'generated');
    expect(repository.items.last.type, 'scan:qrCode');
  });

  test('rejects empty QR content', () async {
    final QrService service = QrService(_MemoryQrRepository());
    expect(() => service.recordGenerated('   '), throwsA(isA<FormatException>()));
  });
}

class _MemoryQrRepository implements QrHistoryRepository {
  final List<QrHistoryEntry> items = <QrHistoryEntry>[];

  @override
  Future<void> add(QrHistoryEntry entry) async => items.add(entry);

  @override
  Future<void> clear() async => items.clear();

  @override
  Stream<List<QrHistoryEntry>> watchAll() => Stream<List<QrHistoryEntry>>.value(items);
}
