import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/core/storage/local_file_service.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/data/drift_document_repository.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase database;
  late DriftDocumentRepository repository;
  late LocalFileService storage;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('workkit-m1-test-');
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDocumentRepository(database);
    storage = LocalFileService.forTesting(tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('imports a selected file into managed storage and persists metadata', () async {
    final File source = File('${tempDirectory.path}/source.pdf');
    await source.writeAsString('sample pdf bytes');

    final DocumentLibraryService service = DocumentLibraryService(
      repository: repository,
      picker: _FakePicker(
        PickedDocument(
          name: 'Invoice.pdf',
          path: source.path,
          sizeBytes: await source.length(),
        ),
      ),
      storage: storage,
    );

    final WorkDocument? imported = await service.importFromDevice();

    expect(imported, isNotNull);
    expect(imported!.name, 'Invoice.pdf');
    expect(imported.type, 'pdf');
    expect(imported.path, isNot(source.path));
    expect(await File(imported.path).readAsString(), 'sample pdf bytes');

    final List<WorkDocument> stored = await repository.getRecent();
    expect(stored, hasLength(1));
    expect(stored.single.id, imported.id);
  });

  test('rename updates display name without changing the managed file path', () async {
    final File source = File('${tempDirectory.path}/photo.jpg');
    await source.writeAsBytes(<int>[1, 2, 3, 4]);

    final DocumentLibraryService service = DocumentLibraryService(
      repository: repository,
      picker: _FakePicker(
        PickedDocument(
          name: 'photo.jpg',
          path: source.path,
          sizeBytes: await source.length(),
        ),
      ),
      storage: storage,
    );

    final WorkDocument imported = (await service.importFromDevice())!;
    final String managedPath = imported.path;

    await service.rename(imported, 'Receipt photo.jpg');

    final WorkDocument? updated = await repository.getById(imported.id);
    expect(updated!.name, 'Receipt photo.jpg');
    expect(updated.path, managedPath);
    expect(await File(managedPath).exists(), isTrue);
  });

  test('delete removes both metadata and the managed local file', () async {
    final File source = File('${tempDirectory.path}/notes.txt');
    await source.writeAsString('private notes');

    final DocumentLibraryService service = DocumentLibraryService(
      repository: repository,
      picker: _FakePicker(
        PickedDocument(
          name: 'notes.txt',
          path: source.path,
          sizeBytes: await source.length(),
        ),
      ),
      storage: storage,
    );

    final WorkDocument imported = (await service.importFromDevice())!;
    expect(await File(imported.path).exists(), isTrue);

    await service.delete(imported);

    expect(await File(imported.path).exists(), isFalse);
    expect(await repository.getById(imported.id), isNull);
  });

  test('cancelled picker does not create document metadata', () async {
    final DocumentLibraryService service = DocumentLibraryService(
      repository: repository,
      picker: const _FakePicker(null),
      storage: storage,
    );

    expect(await service.importFromDevice(), isNull);
    expect(await repository.getRecent(), isEmpty);
  });
}

class _FakePicker implements DocumentPicker {
  const _FakePicker(this.document);

  final PickedDocument? document;

  @override
  Future<PickedDocument?> pick() async => document;
}
