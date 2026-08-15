class SavedSignature {
  const SavedSignature({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final bool isDefault;
}
