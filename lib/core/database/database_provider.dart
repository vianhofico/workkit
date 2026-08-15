import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/app_database.dart';

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});
