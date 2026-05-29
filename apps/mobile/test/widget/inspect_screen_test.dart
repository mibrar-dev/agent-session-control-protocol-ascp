import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/inspect/application/inspect_controller.dart';
import 'package:mobile/features/inspect/data/inspect_repository.dart';
import 'package:mobile/features/inspect/domain/inspect_item.dart';
import 'package:mobile/features/inspect/presentation/inspect_screen.dart';

void main() {
  testWidgets('inspect screen renders artifact viewer chrome', (tester) async {
    final controller = InspectController(
      repository: MemoryInspectRepository(
        items: const [InspectItem.diff('diff_1')],
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InspectScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('middleware.ts'), findsOneWidget);
    expect(find.text('Pending approval'), findsOneWidget);
    expect(find.text('Approve patch'), findsOneWidget);
  });

  testWidgets('inspect screen renders prioritized inspect items', (
    tester,
  ) async {
    final controller = InspectController(
      repository: MemoryInspectRepository(
        items: const [
          InspectItem.artifact('artifact_1'),
          InspectItem.diff('diff_1'),
        ],
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InspectScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('diff_1'), findsOneWidget);
    expect(find.text('artifact_1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('diff_1')).dy,
      lessThan(tester.getTopLeft(find.text('artifact_1')).dy),
    );
  });

  testWidgets('inspect screen renders unsupported reason', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InspectScreen(
          controller: InspectController(
            repository: MemoryInspectRepository(),
            isSupported: false,
            unsupportedReason: 'artifact capability unavailable',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('artifact capability unavailable'), findsOneWidget);
  });
}
