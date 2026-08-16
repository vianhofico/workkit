import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/l10n/app_localizations.dart';

void main() {
  Future<void> pumpLocale(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const <Locale>[Locale('en'), Locale('vi')],
        home: Builder(
          builder: (context) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Column(
                children: <Widget>[
                  Text(l10n.home),
                  Text(l10n.files),
                  Text(l10n.tools),
                  Text(l10n.settings),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('English translations are available', (tester) async {
    await pumpLocale(tester, const Locale('en'));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Vietnamese translations are available', (tester) async {
    await pumpLocale(tester, const Locale('vi'));
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Tệp'), findsOneWidget);
    expect(find.text('Công cụ'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('unsupported locale falls back to English', (tester) async {
    await pumpLocale(tester, const Locale('ko'));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
