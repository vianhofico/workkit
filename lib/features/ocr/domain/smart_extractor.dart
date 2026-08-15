class SmartEntities {
  const SmartEntities({
    this.emails = const <String>[],
    this.phones = const <String>[],
    this.urls = const <String>[],
    this.dates = const <String>[],
    this.money = const <String>[],
  });

  final List<String> emails;
  final List<String> phones;
  final List<String> urls;
  final List<String> dates;
  final List<String> money;

  bool get isEmpty =>
      emails.isEmpty && phones.isEmpty && urls.isEmpty && dates.isEmpty && money.isEmpty;
}

class SmartExtractor {
  const SmartExtractor();

  SmartEntities extract(String text) {
    return SmartEntities(
      emails: _matches(text, RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false)),
      phones: _matches(text, RegExp(r'(?<!\d)(?:\+?84|0)(?:[ .-]?\d){9,10}(?!\d)')),
      urls: _matches(text, RegExp(r'\bhttps?://[^\s<>()]+', caseSensitive: false)),
      dates: _matches(
        text,
        RegExp(r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}-\d{1,2}-\d{1,2})\b'),
      ),
      money: _matches(
        text,
        RegExp(
          r'(?:(?:USD|VND|VNĐ|₫|\$)\s*\d[\d.,]*|\d[\d.,]*\s*(?:USD|VND|VNĐ|₫|đ))',
          caseSensitive: false,
        ),
      ),
    );
  }

  List<String> _matches(String text, RegExp pattern) {
    final Set<String> values = <String>{};
    for (final RegExpMatch match in pattern.allMatches(text)) {
      final String value = match.group(0)?.trim() ?? '';
      if (value.isNotEmpty) {
        values.add(value.replaceFirst(RegExp(r'[.,;:]+$'), ''));
      }
    }
    return values.toList(growable: false);
  }
}
