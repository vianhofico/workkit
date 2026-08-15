import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/features/tools/presentation/tools_screen.dart';

void main() {
  testWidgets('tools remain usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
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

    expect(tester.takeException(), isNull);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Scan document'), findsOneWidget);
    expect(find.text('Create QR'), findsOneWidget);
  });
}
