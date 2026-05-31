import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/mobile_dependencies.dart';
import 'package:mobile/app/app_router.dart';
import 'package:mobile/app/continuum_app.dart';
import 'package:mobile/features/sessions/application/session_list_controller.dart';
import 'package:mobile/features/sessions/data/session_repository.dart';
import 'package:mobile/features/sessions/domain/timeline_event.dart';

void main() {
  test('untrusted route guard sends users to pairing', () {
    final location = resolveInitialLocation(
      isTrusted: false,
      requestedPath: '/sessions',
    );

    expect(location, '/pairing');
  });

  test('trusted route guard keeps allowed path', () {
    final location = resolveInitialLocation(
      isTrusted: true,
      requestedPath: '/sessions',
    );

    expect(location, '/sessions');
  });

  testWidgets('trusted shell renders primary mobile tabs', (tester) async {
    await tester.pumpWidget(const ContinuumMobileApp(isTrusted: true));

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Sessions'), findsWidgets);
    expect(find.text('Approvals'), findsWidgets);
    expect(find.text('Devices'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('trusted shell opens implemented session tab', (tester) async {
    await tester.pumpWidget(const ContinuumMobileApp(isTrusted: true));

    await tester.tap(find.text('Sessions').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('No active sessions'), findsOneWidget);
  });

  testWidgets('trusted shell uses injected mobile dependencies', (
    tester,
  ) async {
    final dependencies = MobileDependencies.memory(
      sessionListController: SessionListController(
        repository: MemorySessionRepository(
          sessions: [
            SessionSummary(
              id: 'sess_injected',
              title: 'Injected live session',
              status: 'running',
              updatedAt: DateTime.utc(2026, 5, 25, 12),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      ContinuumMobileApp(isTrusted: true, dependencies: dependencies),
    );

    await tester.tap(find.text('Sessions').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('Injected live session'), findsOneWidget);
  });
}
