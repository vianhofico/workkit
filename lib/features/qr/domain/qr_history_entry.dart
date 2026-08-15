class QrHistoryEntry {
  const QrHistoryEntry({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String content;
  final DateTime createdAt;

  bool get isGenerated => type == 'generated';
}
