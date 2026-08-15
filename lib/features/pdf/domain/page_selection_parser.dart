class PageSelectionParser {
  const PageSelectionParser._();

  static List<int> parse(String input) {
    final List<int> pages = <int>[];
    for (final String token in input.split(',')) {
      final String value = token.trim();
      if (value.isEmpty) {
        continue;
      }
      if (value.contains('-')) {
        final List<String> bounds = value.split('-');
        if (bounds.length != 2) {
          throw const FormatException('Invalid page range.');
        }
        final int? start = int.tryParse(bounds[0].trim());
        final int? end = int.tryParse(bounds[1].trim());
        if (start == null || end == null || start < 1 || end < start) {
          throw const FormatException('Pages must be positive, e.g. 1,3-5.');
        }
        for (int page = start; page <= end; page++) {
          pages.add(page - 1);
        }
      } else {
        final int? page = int.tryParse(value);
        if (page == null || page < 1) {
          throw const FormatException('Pages must be positive, e.g. 1,3-5.');
        }
        pages.add(page - 1);
      }
    }
    if (pages.isEmpty) {
      throw const FormatException('Enter at least one page.');
    }
    return pages.toSet().toList(growable: false);
  }

  static List<int> parseOrder(String input) {
    final List<int> order = parse(input);
    if (order.toSet().length != order.length) {
      throw const FormatException('Page order cannot contain duplicates.');
    }
    return order;
  }
}
