import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/features/pdf/domain/page_selection_parser.dart';

void main() {
  test('parses one-based pages and ranges into zero-based indices', () {
    expect(PageSelectionParser.parse('1, 3-5'), <int>[0, 2, 3, 4]);
  });

  test('rejects invalid pages', () {
    expect(() => PageSelectionParser.parse('0,2'), throwsFormatException);
  });
}
