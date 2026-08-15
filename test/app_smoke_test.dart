import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/app/workkit_app.dart';

void main() {
  testWidgets('shows WorkKit home foundation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkKitApp()));
    await tester.pumpAndSettle();

    expect(find.text('WorkKit'), findsOneWidget);
    expect(find.text('Scan a document'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });
}
