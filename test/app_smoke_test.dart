import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workkit/app/workkit_app.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

void main() {
  testWidgets('shows WorkKit home foundation', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(
            (ref) => Stream<List<WorkDocument>>.value(
              const <WorkDocument>[],
            ),
          ),
        ],
        child: const WorkKitApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('WorkKit'), findsOneWidget);
    expect(find.text('Import a file'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });
}
