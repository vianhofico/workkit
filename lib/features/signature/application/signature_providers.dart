import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/database/database_provider.dart';
import 'package:workkit/core/storage/local_file_service_provider.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/signature/application/signature_service.dart';
import 'package:workkit/features/signature/data/drift_signature_repository.dart';
import 'package:workkit/features/signature/data/pdf_manipulator_signature_engine.dart';
import 'package:workkit/features/signature/domain/saved_signature.dart';
import 'package:workkit/features/signature/domain/signature_pdf_engine.dart';
import 'package:workkit/features/signature/domain/signature_repository.dart';

final Provider<SignatureRepository> signatureRepositoryProvider =
    Provider<SignatureRepository>((ref) {
  return DriftSignatureRepository(ref.watch(appDatabaseProvider));
});

final Provider<SignaturePdfEngine> signaturePdfEngineProvider =
    Provider<SignaturePdfEngine>((ref) => const PdfManipulatorSignatureEngine());

final FutureProvider<SignatureService> signatureServiceProvider =
    FutureProvider<SignatureService>((ref) async {
  return SignatureService(
    repository: ref.watch(signatureRepositoryProvider),
    storage: await ref.watch(localFileServiceProvider.future),
    library: await ref.watch(documentLibraryServiceProvider.future),
    pdfEngine: ref.watch(signaturePdfEngineProvider),
  );
});

final StreamProvider<List<SavedSignature>> signaturesProvider =
    StreamProvider<List<SavedSignature>>((ref) {
  return ref.watch(signatureRepositoryProvider).watchAll();
});
