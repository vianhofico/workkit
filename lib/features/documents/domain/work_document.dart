class WorkDocument {
  const WorkDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    this.thumbnailPath,
    this.pageCount,
  });

  final String id;
  final String name;
  final String type;
  final String path;
  final String? thumbnailPath;
  final int sizeBytes;
  final int? pageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
}
