import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:workkit/core/database/app_database.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/core/storage/local_file_service.dart';

class BackupRestoreSummary {
  const BackupRestoreSummary({
    required this.documents,
    required this.signatures,
  });

  final int documents;
  final int signatures;
}

class BackupService {
  const BackupService({required this.database, required this.storage});

  static const String _magic = 'WORKKIT_BACKUP_V1';
  static const int _formatVersion = 1;
  static const int _maxManifestBytes = 16 * 1024 * 1024;

  final AppDatabase database;
  final LocalFileService storage;

  Future<File> createBackup() async {
    final documentRows = await database.select(database.documents).get();
    final ocrRows = await database.select(database.ocrResults).get();
    final noteRows = await database.select(database.notes).get();
    final signatureRows = await database.select(database.signatures).get();
    final qrRows = await database.select(database.qrHistory).get();
    final settingRows = await database.select(database.appSettings).get();

    final List<_PayloadFile> payloadFiles = <_PayloadFile>[];
    final List<Map<String, Object?>> documents = <Map<String, Object?>>[];
    for (final row in documentRows) {
      final String relative = _documentRelative(row.id, row.path);
      payloadFiles.add(await _requiredPayload(row.path, relative));
      String? thumbnailRelative;
      if (row.thumbnailPath != null && row.thumbnailPath!.isNotEmpty) {
        final File thumbnail = File(row.thumbnailPath!);
        if (await thumbnail.exists()) {
          thumbnailRelative = _thumbnailRelative(row.id, row.thumbnailPath!);
          payloadFiles.add(
            _PayloadFile(
              sourcePath: thumbnail.path,
              relativePath: thumbnailRelative,
              size: await thumbnail.length(),
            ),
          );
        }
      }
      documents.add(<String, Object?>{
        'id': row.id,
        'name': row.name,
        'type': row.type,
        'relativePath': relative,
        'thumbnailRelativePath': thumbnailRelative,
        'sizeBytes': row.sizeBytes,
        'pageCount': row.pageCount,
        'isFavorite': row.isFavorite,
        'createdAt': row.createdAt.toUtc().toIso8601String(),
        'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      });
    }

    final List<Map<String, Object?>> signatures = <Map<String, Object?>>[];
    for (final row in signatureRows) {
      final String relative = 'signatures/${row.id}.png';
      payloadFiles.add(await _requiredPayload(row.path, relative));
      signatures.add(<String, Object?>{
        'id': row.id,
        'name': row.name,
        'relativePath': relative,
        'isDefault': row.isDefault,
        'createdAt': row.createdAt.toUtc().toIso8601String(),
      });
    }

    final Map<String, Object?> manifest = <String, Object?>{
      'formatVersion': _formatVersion,
      'databaseSchemaVersion': database.schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'documents': documents,
      'ocrResults': ocrRows
          .map(
            (row) => <String, Object?>{
              'id': row.id,
              'documentId': row.documentId,
              'textContent': row.textContent,
              'language': row.language,
              'createdAt': row.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'notes': noteRows
          .map(
            (row) => <String, Object?>{
              'id': row.id,
              'title': row.title,
              'content': row.content,
              'isPinned': row.isPinned,
              'createdAt': row.createdAt.toUtc().toIso8601String(),
              'updatedAt': row.updatedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'signatures': signatures,
      'qrHistory': qrRows
          .map(
            (row) => <String, Object?>{
              'id': row.id,
              'type': row.type,
              'content': row.content,
              'createdAt': row.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'appSettings': settingRows
          .map(
            (row) => <String, Object?>{
              'key': row.key,
              'value': row.value,
            },
          )
          .toList(),
      'files': payloadFiles
          .map(
            (file) => <String, Object?>{
              'relativePath': file.relativePath,
              'size': file.size,
            },
          )
          .toList(),
    };

    final Uint8List manifestBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
    if (manifestBytes.length > _maxManifestBytes) {
      throw const StorageFailure('Backup metadata is unexpectedly large.');
    }

    final Directory backups = await storage.ensureDirectory('backups');
    final String stamp = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    final File target = File(
      '${backups.path}${Platform.pathSeparator}workkit-backup-$stamp.wkbak',
    );
    final File temp = File('${target.path}.workkit-tmp');
    RandomAccessFile? output;
    try {
      output = await temp.open(mode: FileMode.write);
      await output.writeString('$_magic\n');
      await output.writeString('${manifestBytes.length}\n');
      await output.writeFrom(manifestBytes);
      for (final _PayloadFile payload in payloadFiles) {
        await _appendFile(output, File(payload.sourcePath));
      }
      await output.flush();
      await output.close();
      output = null;
      if (await target.exists()) {
        await target.delete();
      }
      return await temp.rename(target.path);
    } on FileSystemException catch (error) {
      throw StorageFailure(
        'Unable to create backup. Check available device storage and try again.',
        cause: error,
      );
    } finally {
      await output?.close();
      if (await temp.exists()) {
        await temp.delete();
      }
    }
  }

  Future<BackupRestoreSummary> restoreBackup(String backupPath) async {
    final File backup = File(backupPath);
    if (!await backup.exists()) {
      throw const StorageFailure('The selected backup file is unavailable.');
    }

    final String stamp = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    final Directory staging = Directory(
      '${storage.rootDirectory.path}${Platform.pathSeparator}workkit_restore_staging_$stamp',
    );
    Directory? restoredRoot;
    RandomAccessFile? input;
    try {
      input = await backup.open();
      final String magic = await _readLine(input, 128);
      if (magic != _magic) {
        throw const FormatException('This is not a WorkKit backup file.');
      }
      final int? manifestLength = int.tryParse(await _readLine(input, 32));
      if (manifestLength == null ||
          manifestLength <= 0 ||
          manifestLength > _maxManifestBytes) {
        throw const FormatException('The backup manifest is invalid.');
      }
      final Uint8List manifestBytes = await input.read(manifestLength);
      if (manifestBytes.length != manifestLength) {
        throw const FormatException('The backup file is truncated.');
      }
      final Object? decoded = jsonDecode(utf8.decode(manifestBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('The backup manifest is invalid.');
      }
      final Map<String, dynamic> manifest = decoded;
      if (_asInt(manifest['formatVersion']) != _formatVersion) {
        throw const FormatException('This backup version is not supported.');
      }
      final int sourceSchema = _asInt(manifest['databaseSchemaVersion']);
      if (sourceSchema > database.schemaVersion) {
        throw const FormatException(
          'This backup was created by a newer WorkKit database version.',
        );
      }

      await staging.create(recursive: true);
      for (final Map<String, dynamic> entry in _asMaps(manifest['files'])) {
        final String relative = _safeRelative(_asString(entry['relativePath']));
        final int size = _asInt(entry['size']);
        if (size < 0) {
          throw const FormatException('A backup file size is invalid.');
        }
        final File output = File(_join(staging.path, relative));
        await output.parent.create(recursive: true);
        await _copyExact(input, output, size);
      }
      await input.close();
      input = null;

      final List<String> oldPaths = await _currentManagedPaths();
      restoredRoot = await staging.rename(
        '${storage.rootDirectory.path}${Platform.pathSeparator}restored-$stamp',
      );
      await _replaceDatabase(manifest, restoredRoot);
      await _cleanupOldPaths(oldPaths, restoredRoot.path);

      return BackupRestoreSummary(
        documents: _asMaps(manifest['documents']).length,
        signatures: _asMaps(manifest['signatures']).length,
      );
    } on FileSystemException catch (error) {
      throw StorageFailure(
        'Unable to restore backup. Check available device storage and try again.',
        cause: error,
      );
    } finally {
      await input?.close();
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
      if (restoredRoot != null &&
          await restoredRoot.exists() &&
          !(await _databaseReferencesRoot(restoredRoot.path))) {
        await restoredRoot.delete(recursive: true);
      }
    }
  }

  Future<void> _replaceDatabase(
    Map<String, dynamic> manifest,
    Directory restoredRoot,
  ) async {
    final List<Map<String, dynamic>> documents = _asMaps(manifest['documents']);
    final List<Map<String, dynamic>> ocrResults = _asMaps(manifest['ocrResults']);
    final List<Map<String, dynamic>> notes = _asMaps(manifest['notes']);
    final List<Map<String, dynamic>> signatures = _asMaps(manifest['signatures']);
    final List<Map<String, dynamic>> qrHistory = _asMaps(manifest['qrHistory']);
    final List<Map<String, dynamic>> appSettings = _asMaps(manifest['appSettings']);

    await database.transaction(() async {
      await database.delete(database.ocrResults).go();
      await database.delete(database.toolHistory).go();
      await database.delete(database.documents).go();
      await database.delete(database.notes).go();
      await database.delete(database.signatures).go();
      await database.delete(database.qrHistory).go();
      await database.delete(database.appSettings).go();

      for (final Map<String, dynamic> row in documents) {
        final String relative = _safeRelative(_asString(row['relativePath']));
        final String? thumbnailRelative = _nullableString(
          row['thumbnailRelativePath'],
        );
        await database.into(database.documents).insert(
              DocumentsCompanion.insert(
                id: _asString(row['id']),
                name: _asString(row['name']),
                type: _asString(row['type']),
                path: _join(restoredRoot.path, relative),
                thumbnailPath: Value<String?>(
                  thumbnailRelative == null
                      ? null
                      : _join(
                          restoredRoot.path,
                          _safeRelative(thumbnailRelative),
                        ),
                ),
                sizeBytes: Value<int>(_asInt(row['sizeBytes'])),
                pageCount: Value<int?>(_nullableInt(row['pageCount'])),
                isFavorite: Value<bool>(_asBool(row['isFavorite'])),
                createdAt: Value<DateTime>(_asDate(row['createdAt'])),
                updatedAt: Value<DateTime>(_asDate(row['updatedAt'])),
              ),
            );
      }
      for (final Map<String, dynamic> row in ocrResults) {
        await database.into(database.ocrResults).insert(
              OcrResultsCompanion.insert(
                id: _asString(row['id']),
                documentId: _asString(row['documentId']),
                textContent: _asString(row['textContent']),
                language: Value<String?>(_nullableString(row['language'])),
                createdAt: Value<DateTime>(_asDate(row['createdAt'])),
              ),
            );
      }
      for (final Map<String, dynamic> row in notes) {
        await database.into(database.notes).insert(
              NotesCompanion.insert(
                id: _asString(row['id']),
                title: Value<String>(_asString(row['title'])),
                content: Value<String>(_asString(row['content'])),
                isPinned: Value<bool>(_asBool(row['isPinned'])),
                createdAt: Value<DateTime>(_asDate(row['createdAt'])),
                updatedAt: Value<DateTime>(_asDate(row['updatedAt'])),
              ),
            );
      }
      for (final Map<String, dynamic> row in signatures) {
        await database.into(database.signatures).insert(
              SignaturesCompanion.insert(
                id: _asString(row['id']),
                name: _asString(row['name']),
                path: _join(
                  restoredRoot.path,
                  _safeRelative(_asString(row['relativePath'])),
                ),
                isDefault: Value<bool>(_asBool(row['isDefault'])),
                createdAt: Value<DateTime>(_asDate(row['createdAt'])),
              ),
            );
      }
      for (final Map<String, dynamic> row in qrHistory) {
        await database.into(database.qrHistory).insert(
              QrHistoryCompanion.insert(
                id: _asString(row['id']),
                type: _asString(row['type']),
                content: _asString(row['content']),
                createdAt: Value<DateTime>(_asDate(row['createdAt'])),
              ),
            );
      }
      for (final Map<String, dynamic> row in appSettings) {
        await database.into(database.appSettings).insert(
              AppSettingsCompanion.insert(
                key: _asString(row['key']),
                value: _asString(row['value']),
              ),
            );
      }
    });
  }

  Future<List<String>> _currentManagedPaths() async {
    final documents = await database.select(database.documents).get();
    final signatures = await database.select(database.signatures).get();
    return <String>[
      for (final row in documents) row.path,
      for (final row in documents)
        if (row.thumbnailPath != null) row.thumbnailPath!,
      for (final row in signatures) row.path,
    ];
  }

  Future<bool> _databaseReferencesRoot(String root) async {
    final documents = await database.select(database.documents).get();
    if (documents.any((row) => row.path.startsWith(root))) {
      return true;
    }
    final signatures = await database.select(database.signatures).get();
    return signatures.any((row) => row.path.startsWith(root));
  }

  Future<void> _cleanupOldPaths(List<String> paths, String restoredRoot) async {
    for (final String path in paths.toSet()) {
      if (path.startsWith(restoredRoot)) continue;
      try {
        final File file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // Restore already committed; stale files are safe to leave for recovery.
      }
    }
  }

  Future<_PayloadFile> _requiredPayload(
    String sourcePath,
    String relativePath,
  ) async {
    final File file = File(sourcePath);
    if (!await file.exists()) {
      throw StorageFailure('Cannot back up missing file: ${_fileName(sourcePath)}');
    }
    return _PayloadFile(
      sourcePath: sourcePath,
      relativePath: relativePath,
      size: await file.length(),
    );
  }

  Future<void> _appendFile(RandomAccessFile output, File source) async {
    final RandomAccessFile input = await source.open();
    try {
      while (true) {
        final Uint8List chunk = await input.read(64 * 1024);
        if (chunk.isEmpty) break;
        await output.writeFrom(chunk);
      }
    } finally {
      await input.close();
    }
  }

  Future<void> _copyExact(
    RandomAccessFile input,
    File output,
    int size,
  ) async {
    final RandomAccessFile sink = await output.open(mode: FileMode.write);
    int remaining = size;
    try {
      while (remaining > 0) {
        final int count = remaining > 64 * 1024 ? 64 * 1024 : remaining;
        final Uint8List chunk = await input.read(count);
        if (chunk.isEmpty) {
          throw const FormatException('The backup file is truncated.');
        }
        await sink.writeFrom(chunk);
        remaining -= chunk.length;
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Future<String> _readLine(RandomAccessFile input, int maxLength) async {
    final BytesBuilder bytes = BytesBuilder(copy: false);
    int length = 0;
    while (true) {
      final Uint8List chunk = await input.read(1);
      if (chunk.isEmpty) {
        throw const FormatException('The backup header is truncated.');
      }
      if (chunk.first == 10) {
        return utf8.decode(bytes.takeBytes());
      }
      bytes.addByte(chunk.first);
      length++;
      if (length > maxLength) {
        throw const FormatException('The backup header is invalid.');
      }
    }
  }

  String _documentRelative(String id, String path) {
    final String extension = _extension(path);
    return extension.isEmpty ? 'documents/$id' : 'documents/$id.$extension';
  }

  String _thumbnailRelative(String id, String path) {
    final String extension = _extension(path);
    return extension.isEmpty
        ? 'thumbnails/$id-thumbnail'
        : 'thumbnails/$id-thumbnail.$extension';
  }

  String _extension(String path) {
    final String name = _fileName(path);
    final int dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  String _fileName(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  String _safeRelative(String value) {
    final String normalized = value.replaceAll('\\', '/');
    if (normalized.startsWith('/') || normalized.contains(':')) {
      throw const FormatException('Backup contains an unsafe file path.');
    }
    final List<String> parts = normalized.split('/');
    if (parts.length < 2 ||
        parts.any((part) => part.isEmpty || part == '.' || part == '..') ||
        !<String>{'documents', 'thumbnails', 'signatures'}.contains(parts.first)) {
      throw const FormatException('Backup contains an unsafe file path.');
    }
    return parts.join('/');
  }

  String _join(String root, String relative) {
    return '$root${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  }

  List<Map<String, dynamic>> _asMaps(Object? value) {
    if (value == null) return <Map<String, dynamic>>[];
    if (value is! List) {
      throw const FormatException('The backup manifest is invalid.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw const FormatException('The backup manifest is invalid.');
      }
      final Map<String, dynamic> result = <String, dynamic>{};
      item.forEach((key, dynamic itemValue) {
        if (key is! String) {
          throw const FormatException('The backup manifest is invalid.');
        }
        result[key] = itemValue;
      });
      return result;
    }).toList(growable: false);
  }

  String _asString(Object? value) {
    if (value is String) return value;
    throw const FormatException('The backup manifest is invalid.');
  }

  String? _nullableString(Object? value) {
    if (value == null) return null;
    return _asString(value);
  }

  int _asInt(Object? value) {
    if (value is num) return value.toInt();
    throw const FormatException('The backup manifest is invalid.');
  }

  int? _nullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    throw const FormatException('The backup manifest is invalid.');
  }

  DateTime _asDate(Object? value) {
    final DateTime? parsed = DateTime.tryParse(_asString(value));
    if (parsed == null) {
      throw const FormatException('The backup manifest contains an invalid date.');
    }
    return parsed.toLocal();
  }
}

class _PayloadFile {
  const _PayloadFile({
    required this.sourcePath,
    required this.relativePath,
    required this.size,
  });

  final String sourcePath;
  final String relativePath;
  final int size;
}
