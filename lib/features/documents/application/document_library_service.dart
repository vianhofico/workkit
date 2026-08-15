// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'package:workkit/core/storage/local_file_service.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';
import 'package:workkit/features/documents/domain/document_repository.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

class DocumentLibraryService {
  const DocumentLibraryService({
    required DocumentRepository repository,
    required DocumentPicker picker,
    required LocalFileService storage,
  })  : _repository = repository,
        _picker = picker,
        _storage = storage;

  final DocumentRepository _repository;
  final DocumentPicker _picker;
  final LocalFileService _storage;

  Future<WorkDocument?> importFromDevice() async {
    final PickedDocument? picked = await _picker.pick();
    if (picked == null) {
      return null;
    }

    final DateTime now = DateTime.now();
    final String id = _createId(now);
    final String extension = _extensionOf(picked.name);
    final String storageName = extension.isEmpty ? id : '$id.$extension';

    final importedFile = await _storage.copyIntoStorage(
      sourcePath: picked.path,
      directory: 'documents',
      fileName: storageName,
    );

    final WorkDocument document = WorkDocument(
      id: id,
      name: picked.name.trim().isEmpty ? 'Untitled document' : picked.name.trim(),
      type: _typeForExtension(extension),
      path: importedFile.path,
      sizeBytes: await importedFile.length(),
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
    );

    try {
      await _repository.add(document);
      return document;
    } catch (_) {
      await _storage.deleteIfExists(importedFile.path);
      rethrow;
    }
  }

  Future<void> rename(WorkDocument document, String newName) async {
    final String normalizedName = newName.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('Document name cannot be empty.');
    }
    await _repository.rename(document.id, normalizedName);
  }

  Future<void> delete(WorkDocument document) async {
    await _storage.deleteIfExists(document.path);
    await _repository.deleteById(document.id);
  }

  String _createId(DateTime now) {
    final int random = Random.secure().nextInt(0x7fffffff);
    return '${now.microsecondsSinceEpoch.toRadixString(36)}-${random.toRadixString(36)}';
  }

  String _extensionOf(String fileName) {
    final int separator = fileName.lastIndexOf('.');
    if (separator <= 0 || separator == fileName.length - 1) {
      return '';
    }

    return fileName
        .substring(separator + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _typeForExtension(String extension) {
    if (extension == 'pdf') {
      return 'pdf';
    }
    if (<String>{'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'}.contains(extension)) {
      return 'image';
    }
    if (<String>{'txt', 'md', 'csv', 'json', 'xml'}.contains(extension)) {
      return 'text';
    }
    if (<String>{'doc', 'docx', 'odt', 'rtf'}.contains(extension)) {
      return 'document';
    }
    if (<String>{'xls', 'xlsx', 'ods'}.contains(extension)) {
      return 'spreadsheet';
    }
    if (<String>{'ppt', 'pptx', 'odp'}.contains(extension)) {
      return 'presentation';
    }
    return 'file';
  }
}
