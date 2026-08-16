import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/features/tools/presentation/tools_screen.dart';
import 'package:workkit/l10n/app_localizations.dart';

void main() {
  Future<void> pumpTools(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const <Locale>[Locale('en'), Locale('vi')],
        builder: (context, child) {
          final MediaQueryData data = MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          );
          return MediaQuery(data: data, child: child!);
        },
        home: const Scaffold(body: ToolsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('English tools remain usable at 200 percent text scale', (tester) async {
    await pumpTools(tester, const Locale('en'));
    expect(tester.takeException(), isNull);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Scan document'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Create QR'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vietnamese tools remain usable at 200 percent text scale', (tester) async {
    await pumpTools(tester, const Locale('vi'));
    expect(tester.takeException(), isNull);
    expect(find.text('Công cụ'), findsOneWidget);
    expect(find.text('Quét tài liệu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tạo QR'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
