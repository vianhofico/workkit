import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/scanner/application/scanner_service.dart';
import 'package:workkit/features/scanner/data/native_document_scanner.dart';
import 'package:workkit/features/scanner/domain/document_scanner.dart';

final Provider<DocumentScanner> documentScannerProvider =
    Provider<DocumentScanner>((ref) => const NativeDocumentScanner());

final FutureProvider<ScannerService> scannerServiceProvider =
    FutureProvider<ScannerService>((ref) async {
  return ScannerService(
    scanner: ref.watch(documentScannerProvider),
    library: await ref.watch(documentLibraryServiceProvider.future),
  );
});
