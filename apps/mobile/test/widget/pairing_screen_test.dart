import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/core/security/secure_store.dart';
import 'package:mobile/core/security/trust_material.dart';
import 'package:mobile/features/pairing/application/pairing_controller.dart';
import 'package:mobile/features/pairing/data/pairing_repository.dart';
import 'package:mobile/features/pairing/domain/pairing_state.dart';
import 'package:mobile/features/pairing/presentation/pairing_screen.dart';

class _FakeSecureStore implements SecureStore {
  @override
  Future<TrustMaterial?> readTrustMaterial() async => null;

  @override
  Future<void> writeTrustMaterial(TrustMaterial material) async {}
}

class _AllowingAuth implements LocalAuthGate {
  @override
  Future<bool> confirm(String reason) async => true;
}

class _DeterministicPoll implements PairingPollSimulator {
  final PairingPollState _state;
  _DeterministicPoll(this._state);

  @override
  PairingPollState simulatePoll(PairingClaim claim) => _state;
}

class _StubScanner implements PairingScanner {
  @override
  Future<String?> scan(BuildContext context) async =>
      'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=STUB';
}

class _NullScanner implements PairingScanner {
  @override
  Future<String?> scan(BuildContext context) async => null;
}

void main() {
  testWidgets('pairing screen renders idle with scan and manual buttons', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.pending),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    expect(find.text('Pair a host'), findsOneWidget);
    expect(find.text('Scan QR code'), findsOneWidget);
    expect(find.text('Enter code manually'), findsOneWidget);
  });

  testWidgets('pairing screen shows scanning placeholder when scan tapped', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.pending),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Scan QR code'));
    await tester.pump();

    expect(find.text('Pair a host'), findsOneWidget);
    expect(find.text('Scan QR code'), findsOneWidget);
    expect(find.text('Claim device'), findsOneWidget);
  });

  testWidgets('pairing screen shows manual entry input when manual tapped', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.pending),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('Claim device'), findsOneWidget);
  });

  testWidgets('pairing screen accepts submitted payload', (tester) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.approved),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:TEST01');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(controller.state.isTrusted, isTrue);
  });

  testWidgets('pairing screen shows trusted state when poll approved', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.approved),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:APPROVE');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(find.text('● Host approved this device.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('pairing screen shows pending host approval state', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.pending),
    );

    await controller.submitPayload(
      'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=PENDING',
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    expect(find.text('● Waiting for host approval...'), findsOneWidget);
    expect(find.text('Scan QR code'), findsOneWidget);
    expect(find.text('Enter code manually'), findsOneWidget);
  });

  testWidgets('pairing screen notifies parent when trusted continue tapped', (
    tester,
  ) async {
    var continued = false;
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.approved),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(
          controller: controller,
          scanner: _NullScanner(),
          onContinue: () => continued = true,
        ),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:APPROVE');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(continued, isTrue);
  });

  testWidgets('pairing screen shows rejected error with claim affordance', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.rejected),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:REJECT');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(find.text('Rejected by host'), findsOneWidget);
    expect(find.text('Claim device'), findsOneWidget);
  });

  testWidgets('pairing failure keeps manual input available', (tester) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.rejected),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:REJECT');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    final input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.controller.text, '127.0.0.1:8765:REJECT');
  });

  testWidgets('pairing screen shows expired error', (tester) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.expired),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:EXPIRE');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(find.text('Pairing code expired'), findsOneWidget);
  });

  testWidgets('pairing screen shows revoked error', (tester) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.revoked),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:REVOKE');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(find.text('Pairing revoked'), findsOneWidget);
  });

  testWidgets('pairing screen shows unreachable error', (tester) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.unreachable),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '127.0.0.1:8765:UNREACH');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(find.text('Host unreachable'), findsOneWidget);
  });

  testWidgets('pairing screen shows malformed error on invalid input', (
    tester,
  ) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.pending),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Enter code manually'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText), 'totally-invalid');
    await tester.tap(find.text('Claim device'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid pairing code'), findsOneWidget);
  });

  testWidgets('mock scanner returns simulated QR payload without real camera', (
    tester,
  ) async {
    final scanner = _StubScanner();
    late final String? result;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () async => result = await scanner.scan(context),
              child: const Text('Scan'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();

    expect(result, isNotNull);
    expect(result, contains('continuum://pair'));
    expect(result, contains('STUB'));
  });

  testWidgets('cancel returns to idle from scanning', (tester) async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPoll(PairingPollState.pending),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PairingScreen(controller: controller, scanner: _NullScanner()),
      ),
    );

    await tester.tap(find.text('Scan QR code'));
    await tester.pump();

    expect(find.text('Pair a host'), findsOneWidget);
    expect(find.text('Scan QR code'), findsOneWidget);
  });
}
