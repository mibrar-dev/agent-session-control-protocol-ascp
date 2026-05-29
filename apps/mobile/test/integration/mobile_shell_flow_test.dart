import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/app/continuum_app.dart';
import 'package:mobile/app/mobile_dependencies.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/core/security/secure_store.dart';
import 'package:mobile/core/security/trust_material.dart';
import 'package:mobile/features/approvals/application/approval_queue_controller.dart';
import 'package:mobile/features/approvals/data/approval_repository.dart';
import 'package:mobile/features/approvals/domain/approval_view_model.dart';
import 'package:mobile/features/pairing/application/pairing_controller.dart';
import 'package:mobile/features/pairing/data/pairing_repository.dart';
import 'package:mobile/features/pairing/domain/pairing_state.dart';
import 'package:mobile/features/sessions/application/session_list_controller.dart';
import 'package:mobile/features/sessions/data/session_repository.dart';
import 'package:mobile/features/sessions/domain/timeline_event.dart';

class _AllowingAuth implements LocalAuthGate {
  @override
  Future<bool> confirm(String reason) async => true;
}

class _ApprovedPoll implements PairingPollSimulator {
  @override
  PairingPollState simulatePoll(PairingClaim claim) =>
      PairingPollState.approved;
}

class _FakeSubscriptionRepository implements SessionSubscriptionRepository {
  final _controller = StreamController<TimelineEvent>.broadcast();

  void add(TimelineEvent event) {
    _controller.add(event);
  }

  @override
  Future<SessionEventSubscription> subscribeTimeline({
    required String sessionId,
    int? fromSequence,
  }) async {
    return SessionEventSubscription(
      id: 'sub_$sessionId',
      events: _controller.stream,
      cancel: () => _controller.close(),
    );
  }
}

void main() {
  testWidgets('first-run shell exposes pairing scan and manual paths', (
    tester,
  ) async {
    await tester.pumpWidget(const ContinuumMobileApp());

    expect(find.text('Continuum'), findsOneWidget);
    expect(find.text('Pair New Device'), findsOneWidget);
    expect(find.text('Scan QR code'), findsOneWidget);

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('trusted shell can move from sessions to approvals', (
    tester,
  ) async {
    final dependencies = MobileDependencies.memory(
      sessionListController: SessionListController(
        repository: MemorySessionRepository(
          sessions: [
            SessionSummary(
              id: 'sess_live',
              title: 'Live ASCP session',
              status: 'running',
              updatedAt: DateTime.utc(2026, 5, 25, 13),
            ),
          ],
        ),
      ),
      approvalQueueController: ApprovalQueueController(
        repository: MemoryApprovalRepository(
          approvals: [
            ApprovalViewModel.pending(
              id: 'approval_live',
              sessionId: 'sess_live',
              isActionable: true,
              reason: 'Allow command',
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
    expect(find.text('Live ASCP session'), findsOneWidget);

    await tester.tap(find.text('Approvals').last);
    await tester.pump();
    await tester.pump();
    expect(find.text('Allow command'), findsOneWidget);
  });

  testWidgets('trusted shell opens a live session detail feed', (tester) async {
    final subscriptionRepository = _FakeSubscriptionRepository();
    final dependencies = MobileDependencies.memory(
      sessionListController: SessionListController(
        repository: MemorySessionRepository(
          sessions: [
            SessionSummary(
              id: 'sess_live',
              title: 'Live ASCP session',
              status: 'running',
              updatedAt: DateTime.utc(2026, 5, 25, 13),
            ),
          ],
        ),
      ),
      createSessionSubscriptionRepository: () => subscriptionRepository,
    );

    await tester.pumpWidget(
      ContinuumMobileApp(isTrusted: true, dependencies: dependencies),
    );

    await tester.tap(find.text('Sessions').last);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Live ASCP session'));
    await tester.pump();

    expect(find.text('Live feed'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    subscriptionRepository.add(
      const TimelineEvent(
        sequence: 8,
        id: 'evt_agent',
        label: 'message.agent Thinking through the next patch',
      ),
    );
    await tester.pump();

    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Thinking through the next patch'), findsOneWidget);
  });

  testWidgets('successful first-run pairing can enter trusted shell', (
    tester,
  ) async {
    final dependencies = MobileDependencies.memory(
      pairingController: PairingController(
        secureStore: MemorySecureStore(),
        localAuth: _AllowingAuth(),
        pollSimulator: _ApprovedPoll(),
      ),
    );

    await tester.pumpWidget(ContinuumMobileApp(dependencies: dependencies));

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:APPROVE');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('ASCP Protocol Controller'), findsOneWidget);
    expect(find.text('Sessions'), findsWidgets);
  });

  testWidgets('stored trust material opens trusted shell on startup', (
    tester,
  ) async {
    final secureStore = MemorySecureStore();
    await secureStore.writeTrustMaterial(
      const TrustMaterial(
        hostId: '127.0.0.1:8765',
        deviceId: 'device_mobile',
        secret: 'secret',
      ),
    );
    final dependencies = MobileDependencies.memory(
      pairingController: PairingController(
        secureStore: secureStore,
        localAuth: _AllowingAuth(),
        pollSimulator: _ApprovedPoll(),
      ),
    );

    await tester.pumpWidget(ContinuumMobileApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('ASCP Protocol Controller'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
  });
}
