import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/storage/local_file_service.dart';

void main() {
  late Directory directory;
  late LocalFileService storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workkit_storage_test_');
    storage = LocalFileService.forTesting(directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('removes abandoned atomic temp files', () async {
    final File temp = File('${directory.path}/orphan.workkit-tmp');
    await temp.writeAsBytes(List<int>.filled(128, 1));

    final int recovered = await storage.recoverAbandonedFiles();

    expect(recovered, 128);
    expect(await temp.exists(), isFalse);
  });
}
