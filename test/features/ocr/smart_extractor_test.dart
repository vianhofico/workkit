import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/features/ocr/domain/smart_extractor.dart';

void main() {
  const SmartExtractor extractor = SmartExtractor();

  test('extracts Vietnamese contact, date, URL and money values', () {
    const String text =
        'Liên hệ +84 912 345 678, email anh@example.com ngày 16/08/2026. '
        'Tổng 1.250.000 VND. Xem https://example.vn/invoice';

    final SmartEntities entities = extractor.extract(text);

    expect(entities.emails, contains('anh@example.com'));
    expect(entities.phones, contains('+84 912 345 678'));
    expect(entities.dates, contains('16/08/2026'));
    expect(entities.money, contains('1.250.000 VND'));
    expect(entities.urls, contains('https://example.vn/invoice'));
  });

  test('extracts English ISO date and USD value', () {
    final SmartEntities entities = extractor.extract(
      'Due 2026-09-01. Pay USD 125.50 and email billing@example.org.',
    );

    expect(entities.dates, contains('2026-09-01'));
    expect(entities.money, contains('USD 125.50'));
    expect(entities.emails, contains('billing@example.org'));
  });
}
