import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/backup/backup_service.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/core/storage/local_file_service.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late LocalFileService storage;
  late BackupService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workkit_backup_test_');
    database = AppDatabase.forTesting(NativeDatabase.memory());
    storage = LocalFileService.forTesting(directory);
    service = BackupService(database: database, storage: storage);
  });

  tearDown(() async {
    await database.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('round-trips document, signature and QR data', () async {
    final File documentFile = await storage.atomicWrite(
      directory: 'documents',
      fileName: 'doc-1.txt',
      bytes: utf8.encode('hello workkit'),
    );
    final File signatureFile = await storage.atomicWrite(
      directory: 'signatures',
      fileName: 'sig-1.png',
      bytes: <int>[1, 2, 3, 4],
    );
    final DateTime now = DateTime(2026, 1, 2, 3, 4, 5);
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'doc-1',
            name: 'note.txt',
            type: 'text',
            path: documentFile.path,
            sizeBytes: Value<int>(await documentFile.length()),
            createdAt: Value<DateTime>(now),
            updatedAt: Value<DateTime>(now),
          ),
        );
    await database.into(database.signatures).insert(
          SignaturesCompanion.insert(
            id: 'sig-1',
            name: 'Primary',
            path: signatureFile.path,
            createdAt: Value<DateTime>(now),
          ),
        );
    await database.into(database.qrHistory).insert(
          QrHistoryCompanion.insert(
            id: 'qr-1',
            type: 'generated',
            content: 'https://example.test',
            createdAt: Value<DateTime>(now),
          ),
        );

    final File backup = await service.createBackup();
    await database.delete(database.documents).go();
    await database.delete(database.signatures).go();
    await database.delete(database.qrHistory).go();
    await documentFile.delete();
    await signatureFile.delete();

    final BackupRestoreSummary summary = await service.restoreBackup(backup.path);
    final restoredDocument = await database.select(database.documents).getSingle();
    final restoredSignature = await database.select(database.signatures).getSingle();
    final restoredQr = await database.select(database.qrHistory).getSingle();

    expect(summary.documents, 1);
    expect(summary.signatures, 1);
    expect(await File(restoredDocument.path).readAsString(), 'hello workkit');
    expect(await File(restoredSignature.path).readAsBytes(), <int>[1, 2, 3, 4]);
    expect(restoredQr.content, 'https://example.test');
  });

  test('rejects non-WorkKit backup files', () async {
    final File invalid = File('${directory.path}/invalid.wkbak');
    await invalid.writeAsString('not-a-backup');

    await expectLater(
      service.restoreBackup(invalid.path),
      throwsA(isA<FormatException>()),
    );
  });
}
