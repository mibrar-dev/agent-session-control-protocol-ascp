import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/local_auth_gate.dart';

void main() {
  test('device local auth gate delegates confirmation reason', () async {
    final delegate = _FakeLocalAuthenticator(result: true);
    final gate = DeviceLocalAuthGate(authenticator: delegate);

    final confirmed = await gate.confirm('Revoke this trusted device');

    expect(confirmed, isTrue);
    expect(delegate.reasons, ['Revoke this trusted device']);
  });

  test(
    'device local auth gate denies when device auth is unsupported',
    () async {
      final gate = DeviceLocalAuthGate(
        authenticator: _FakeLocalAuthenticator(
          result: true,
          isSupported: false,
        ),
      );

      final confirmed = await gate.confirm('Store trusted host credentials');

      expect(confirmed, isFalse);
    },
  );
}

class _FakeLocalAuthenticator implements LocalAuthenticator {
  _FakeLocalAuthenticator({required this.result, this.isSupported = true});

  final bool result;
  final bool isSupported;
  final List<String> reasons = [];

  @override
  Future<bool> canAuthenticate() async => isSupported;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return result;
  }
}
