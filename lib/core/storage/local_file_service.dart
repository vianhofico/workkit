import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:workkit/core/errors/app_failure.dart';

class LocalFileService {
  LocalFileService._(this._rootDirectory);

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
      throw StorageFailure('Unable to initialize WorkKit storage.', cause: error);
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
    final String safeName = _sanitizeSegment(fileName);
    final String targetPath =
        '${targetDirectory.path}${Platform.pathSeparator}$safeName';
    final String tempPath = '$targetPath.workkit-tmp';

    try {
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);
      final File targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      return await tempFile.rename(targetPath);
    } on FileSystemException catch (error) {
      final File tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw StorageFailure('Unable to save file safely.', cause: error);
    }
  }

  String _sanitizeSegment(String value) {
    final String sanitized = value
        .trim()
        .replaceAll(RegExp(r'[\/:*?"<>|]'), '_')
        .replaceAll('..', '_');
    if (sanitized.isEmpty) {
      throw const StorageFailure('File or folder name cannot be empty.');
    }
    return sanitized;
  }
}
