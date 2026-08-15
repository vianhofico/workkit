import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:workkit/core/errors/app_failure.dart';

class LocalFileService {
  LocalFileService._(this._rootDirectory);

  LocalFileService.forTesting(Directory rootDirectory)
      : _rootDirectory = rootDirectory;

  final Directory _rootDirectory;

  static Future<LocalFileService> create() async {
    try {
      final Directory documents = await getApplicationDocumentsDirectory();
      final Directory root = Directory(
        '${documents.path}${Platform.pathSeparator}workkit',
      );
      await root.create(recursive: true);
      return LocalFileService._(root);
    } on FileSystemException catch (error) {
      throw _failure('Unable to initialize WorkKit storage.', error);
    }
  }

  Directory get rootDirectory => _rootDirectory;

  Future<Directory> ensureDirectory(String name) async {
    final String safeName = _sanitizeSegment(name);
    final Directory directory = Directory(
      '${_rootDirectory.path}${Platform.pathSeparator}$safeName',
    );

    try {
      return await directory.create(recursive: true);
    } on FileSystemException catch (error) {
      throw _failure('Unable to create local folder.', error);
    }
  }

  Future<File> atomicWrite({
    required String directory,
    required String fileName,
    required List<int> bytes,
  }) async {
    final Directory targetDirectory = await ensureDirectory(directory);
    final String targetPath = _targetPath(targetDirectory, fileName);
    final String tempPath = '$targetPath.workkit-tmp';

    try {
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);
      await _replaceTarget(tempFile, targetPath);
      return File(targetPath);
    } on FileSystemException catch (error) {
      await _deleteTempIfPresent(tempPath);
      throw _failure('Unable to save file safely.', error);
    }
  }

  Future<File> copyIntoStorage({
    required String sourcePath,
    required String directory,
    required String fileName,
  }) async {
    final File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const StorageFailure('The selected file is no longer available.');
    }

    final Directory targetDirectory = await ensureDirectory(directory);
    final String targetPath = _targetPath(targetDirectory, fileName);
    final String tempPath = '$targetPath.workkit-tmp';

    try {
      await _deleteTempIfPresent(tempPath);
      final File tempFile = await sourceFile.copy(tempPath);
      await _replaceTarget(tempFile, targetPath);
      return File(targetPath);
    } on FileSystemException catch (error) {
      await _deleteTempIfPresent(tempPath);
      throw _failure('Unable to import the selected file.', error);
    }
  }

  Future<void> deleteIfExists(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (error) {
      throw _failure('Unable to delete the local file.', error);
    }
  }

  Future<int> recoverAbandonedFiles({bool includeRecent = false}) async {
    int recovered = 0;
    if (await _rootDirectory.exists()) {
      await for (final FileSystemEntity entity
          in _rootDirectory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.workkit-tmp')) {
          recovered += await _entitySize(entity);
          try {
            await entity.delete();
          } on FileSystemException {
            // Best-effort recovery: another operation may still own the file.
          }
        }
      }
      await for (final FileSystemEntity entity
          in _rootDirectory.list(followLinks: false)) {
        final String name = entity.path.split(Platform.pathSeparator).last;
        if (entity is Directory && name.startsWith('workkit_restore_staging_')) {
          recovered += await _entitySize(entity);
          try {
            await entity.delete(recursive: true);
          } on FileSystemException {
            // Best-effort recovery.
          }
        }
      }
    }

    final Directory systemTemp = Directory.systemTemp;
    if (!await systemTemp.exists()) {
      return recovered;
    }
    await for (final FileSystemEntity entity
        in systemTemp.list(followLinks: false)) {
      final String name = entity.path.split(Platform.pathSeparator).last;
      if (!_isWorkKitTempName(name)) {
        continue;
      }
      if (!includeRecent) {
        try {
          final FileStat stat = await entity.stat();
          if (DateTime.now().difference(stat.modified) <
              const Duration(minutes: 30)) {
            continue;
          }
        } on FileSystemException {
          continue;
        }
      }
      recovered += await _entitySize(entity);
      try {
        await entity.delete(recursive: true);
      } on FileSystemException {
        // Best-effort recovery: leave files that cannot be safely removed.
      }
    }
    return recovered;
  }

  String _targetPath(Directory directory, String fileName) {
    final String safeName = _sanitizeSegment(fileName);
    return '${directory.path}${Platform.pathSeparator}$safeName';
  }

  Future<void> _replaceTarget(File tempFile, String targetPath) async {
    final File targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetPath);
  }

  Future<void> _deleteTempIfPresent(String tempPath) async {
    final File tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  String _sanitizeSegment(String value) {
    final String sanitized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll('..', '_');

    if (sanitized.isEmpty) {
      throw const StorageFailure('File or folder name cannot be empty.');
    }

    return sanitized;
  }

  bool _isWorkKitTempName(String name) {
    return name.startsWith('workkit_pdf_') ||
        name.startsWith('workkit_image_') ||
        name.startsWith('workkit_ocr_pdf_') ||
        name.startsWith('workkit_signature_pdf_');
  }

  Future<int> _entitySize(FileSystemEntity entity) async {
    try {
      if (entity is File) {
        return entity.length();
      }
      if (entity is Directory) {
        int total = 0;
        await for (final FileSystemEntity child
            in entity.list(recursive: true, followLinks: false)) {
          if (child is File) {
            total += await child.length();
          }
        }
        return total;
      }
    } on FileSystemException {
      return 0;
    }
    return 0;
  }

  static StorageFailure _failure(
    String fallback,
    FileSystemException error,
  ) {
    final String message = error.message.toLowerCase();
    final bool noSpace = error.osError?.errorCode == 28 ||
        message.contains('no space') ||
        message.contains('disk full');
    if (noSpace) {
      return StorageFailure(
        'Device storage is full. Free some space or use Settings > Recover storage, then try again.',
        cause: error,
      );
    }
    return StorageFailure(fallback, cause: error);
  }
}
