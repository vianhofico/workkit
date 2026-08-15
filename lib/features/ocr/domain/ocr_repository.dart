class StoredOcrText {
  const StoredOcrText({required this.text, this.language});

  final String text;
  final String? language;
}

abstract interface class OcrRepository {
  Future<void> save({
    required String documentId,
    required String text,
    String? language,
  });

  Future<StoredOcrText?> load(String documentId);
}
