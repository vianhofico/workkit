import 'dart:math';

import 'package:drift/drift.dart';
import 'package:workkit/core/database/app_database.dart';

class ToolJobTracker {
  const ToolJobTracker(this._database);

  final AppDatabase _database;

  Future<String> start({required String tool, String? inputPath}) async {
    final DateTime now = DateTime.now();
    final String id =
        'job-${now.microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(0x7fffffff).toRadixString(36)}';
    await _database.into(_database.toolHistory).insert(
          ToolHistoryCompanion.insert(
            id: id,
            tool: tool,
            inputPath: Value<String?>(inputPath),
            status: const Value<String>('running'),
            createdAt: Value<DateTime>(now),
          ),
        );
    return id;
  }

  Future<void> complete(String id, {String? outputPath}) async {
    await (_database.update(_database.toolHistory)
          ..where((row) => row.id.equals(id)))
        .write(
      ToolHistoryCompanion(
        status: const Value<String>('completed'),
        outputPath: Value<String?>(outputPath),
      ),
    );
  }

  Future<void> fail(String id) async {
    await (_database.update(_database.toolHistory)
          ..where((row) => row.id.equals(id)))
        .write(
      const ToolHistoryCompanion(status: Value<String>('failed')),
    );
  }

  Future<int> recoverInterrupted() {
    return (_database.update(_database.toolHistory)
          ..where((row) => row.status.equals('running')))
        .write(
      const ToolHistoryCompanion(status: Value<String>('interrupted')),
    );
  }
}
