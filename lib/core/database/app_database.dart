import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get path => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant<int>(0))();
  IntColumn get pageCount => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant<bool>(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class OcrResults extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  TextColumn get textContent => text()();
  TextColumn get language => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant<String>(''))();
  TextColumn get content => text().withDefault(const Constant<String>(''))();
  BoolColumn get isPinned => boolean().withDefault(const Constant<bool>(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Signatures extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant<bool>(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class QrHistory extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class ToolHistory extends Table {
  TextColumn get id => text()();
  TextColumn get tool => text()();
  TextColumn get inputPath => text().nullable()();
  TextColumn get outputPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant<String>('completed'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(
  tables: <Type>[
    Documents,
    OcrResults,
    Notes,
    Signatures,
    QrHistory,
    ToolHistory,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'workkit'));

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}
