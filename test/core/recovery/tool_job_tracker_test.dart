import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/core/recovery/tool_job_tracker.dart';

void main() {
  late AppDatabase database;
  late ToolJobTracker tracker;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tracker = ToolJobTracker(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('tracks successful jobs', () async {
    final String id = await tracker.start(
      tool: 'pdf:merge',
      inputPath: '/input.pdf',
    );
    await tracker.complete(id, outputPath: '/output.pdf');

    final rows = await database.select(database.toolHistory).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'completed');
    expect(rows.single.outputPath, '/output.pdf');
  });

  test('marks running jobs interrupted after restart', () async {
    await tracker.start(tool: 'ocr', inputPath: '/scan.pdf');
    final int recovered = await tracker.recoverInterrupted();

    final rows = await database.select(database.toolHistory).get();
    expect(recovered, 1);
    expect(rows.single.status, 'interrupted');
  });
}
