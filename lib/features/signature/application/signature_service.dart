import 'dart:math';
import 'dart:typed_data';

import 'package:workkit/core/storage/local_file_service.dart';
import 'package:workkit/features/documents/application/document_library_service.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/signature/domain/saved_signature.dart';
import 'package:workkit/features/signature/domain/signature_pdf_engine.dart';
import 'package:workkit/features/signature/domain/signature_repository.dart';

class SignatureService {
  const SignatureService({
    required this.repository,
    required this.storage,
    required this.library,
    required this.pdfEngine,
  });

  final SignatureRepository repository;
  final LocalFileService storage;
  final DocumentLibraryService library;
  final SignaturePdfEngine pdfEngine;

  Future<SavedSignature> saveSignature(String name, Uint8List pngBytes) async {
    final String normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('Signature name cannot be empty.');
    }
    if (pngBytes.isEmpty) {
      throw const FormatException('Draw a signature before saving.');
    }

    final DateTime now = DateTime.now();
    final String id = '${now.microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(0x7fffffff).toRadixString(36)}';
    final file = await storage.atomicWrite(
      directory: 'signatures',
      fileName: '$id.png',
      bytes: pngBytes,
    );
    final SavedSignature signature = SavedSignature(
      id: id,
      name: normalizedName,
      path: file.path,
      createdAt: now,
    );
    try {
      await repository.save(signature);
      return signature;
    } catch (_) {
      await storage.deleteIfExists(file.path);
      rethrow;
    }
  }

  Future<void> deleteSignature(SavedSignature signature) async {
    await repository.deleteById(signature.id);
    await storage.deleteIfExists(signature.path);
  }

  Future<PdfPageGeometry> pageGeometry(
    WorkDocument document,
    int page, {
    String? password,
  }) {
    return pdfEngine.pageGeometry(document.path, page, password: password);
  }

  Future<WorkDocument> signPdf(
    WorkDocument document,
    SavedSignature signature,
    PdfSignaturePlacement placement, {
    String? password,
  }) async {
    if (document.type != 'pdf') {
      throw const FormatException('Choose a PDF document.');
    }
    final PdfSignatureOutput output = await pdfEngine.placeSignature(
      document.path,
      signature.path,
      placement,
      password: password,
    );
    try {
      return await library.importPath(
        sourcePath: output.path,
        displayName: 'Signed ${document.name}',
      );
    } finally {
      await pdfEngine.cleanup(output);
    }
  }
}
