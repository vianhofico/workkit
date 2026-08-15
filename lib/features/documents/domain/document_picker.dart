class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.path,
    required this.sizeBytes,
  });

  final String name;
  final String path;
  final int sizeBytes;
}

abstract interface class DocumentPicker {
  Future<PickedDocument?> pick();
}
