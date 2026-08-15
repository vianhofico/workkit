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
      throw StorageFailure(
        'Unable to initialize WorkKit storage.',
        cause: error,
      );
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
      throw StorageFailure('Unable to create local folder.', cause: error);
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
      throw StorageFailure('Unable to save file safely.', cause: error);
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
      throw StorageFailure('Unable to import the selected file.', cause: error);
    }
  }

  Future<void> deleteIfExists(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (error) {
      throw StorageFailure('Unable to delete the local file.', cause: error);
    }
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
}
