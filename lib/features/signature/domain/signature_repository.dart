import 'package:workkit/features/signature/domain/saved_signature.dart';

abstract interface class SignatureRepository {
  Stream<List<SavedSignature>> watchAll();
  Future<void> save(SavedSignature signature);
  Future<void> deleteById(String id);
}
