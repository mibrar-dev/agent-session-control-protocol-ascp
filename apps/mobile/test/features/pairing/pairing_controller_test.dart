import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/core/security/secure_store.dart';
import 'package:mobile/core/security/trust_material.dart';
import 'package:mobile/features/pairing/application/pairing_controller.dart';
import 'package:mobile/features/pairing/data/pairing_repository.dart';
import 'package:mobile/features/pairing/domain/pairing_state.dart';

class _FakeSecureStore implements SecureStore {
  TrustMaterial? _material;

  @override
  Future<TrustMaterial?> readTrustMaterial() async => _material;

  @override
  Future<void> writeTrustMaterial(TrustMaterial material) async {
    _material = material;
  }
}

class _AllowingAuth implements LocalAuthGate {
  @override
  Future<bool> confirm(String reason) async => true;
}

class _DenyingAuth implements LocalAuthGate {
  @override
  Future<bool> confirm(String reason) async => false;
}

class _DeterministicPollSimulator implements PairingPollSimulator {
  final Map<String, PairingPollState> _responses;

  _DeterministicPollSimulator(this._responses);

  @override
  PairingPollState simulatePoll(PairingClaim claim) {
    return _responses[claim.code] ?? PairingPollState.pending;
  }
}

class _FakePairingClaimRepository implements PairingClaimRepository {
  _FakePairingClaimRepository(this.outcomes);

  factory _FakePairingClaimRepository.single(PairingPollOutcome outcome) {
    return _FakePairingClaimRepository([outcome]);
  }

  final List<PairingPollOutcome> outcomes;
  final List<PairingPayload> claims = [];
  final List<PairingClaimTicket> polls = [];

  @override
  Future<PairingClaimTicket> claim(
    PairingPayload payload, {
    required String deviceLabel,
    DateTime? claimedAt,
  }) async {
    claims.add(payload);
    return PairingClaimTicket(
      claim: PairingClaim(
        hostUrl: payload.hostUrl,
        code: payload.code,
        claimedAt: claimedAt ?? DateTime.utc(2026, 5, 25, 12),
      ),
      claimToken: 'claim_token',
      sessionId: 'pairing_session',
    );
  }

  @override
  Future<PairingPollOutcome> poll(PairingClaimTicket ticket) async {
    polls.add(ticket);
    if (polls.length <= outcomes.length) {
      return outcomes[polls.length - 1];
    }
    return outcomes.last;
  }
}

void main() {
  test('pairing controller starts idle', () {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPollSimulator({}),
    );

    expect(controller.state.isIdle, isTrue);
  });

  test('pairing controller transitions to scanning', () {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPollSimulator({}),
    );

    controller.startScanning();
    expect(controller.state.isScanning, isTrue);
  });

  test('pairing controller transitions to manual input', () {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPollSimulator({}),
    );

    controller.startManualInput();
    expect(controller.state.isManualInput, isTrue);
  });

  test('pairing controller cancels to idle', () {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPollSimulator({}),
    );

    controller.startScanning();
    controller.cancel();
    expect(controller.state.isIdle, isTrue);
  });

  test('pairing claim/poll state model tracks host and code', () {
    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: '123456',
      claimedAt: DateTime(2026, 5, 25, 12, 0),
    );

    expect(claim.hostUrl.toString(), 'http://127.0.0.1:8765');
    expect(claim.code, '123456');
    expect(claim.claimedAt, DateTime(2026, 5, 25, 12, 0));
  });

  test('QR payload parsing produces a claim-ready payload', () {
    final payload = parsePairingPayload(
      'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=123456',
    );

    expect(payload.hostUrl.toString(), 'http://127.0.0.1:8765');
    expect(payload.code, '123456');
  });

  test('manual payload parser accepts plain URI with query params', () {
    final payload = parseManualPairingPayload(
      'http://127.0.0.1:8765?code=123456',
    );

    expect(payload.hostUrl.toString(), 'http://127.0.0.1:8765');
    expect(payload.code, '123456');
  });

  test('manual payload parser accepts host:port:code format', () {
    final payload = parseManualPairingPayload('127.0.0.1:8765:ABCDEF');

    expect(payload.hostUrl.toString(), 'http://127.0.0.1:8765');
    expect(payload.code, 'ABCDEF');
  });

  test('manual payload parser accepts JSON object', () {
    final payload = parseManualPairingPayload(
      '{"host":"http://127.0.0.1:8765","code":"789XYZ"}',
    );

    expect(payload.hostUrl.toString(), 'http://127.0.0.1:8765');
    expect(payload.code, '789XYZ');
  });

  test('malformed QR payload throws with malformed failure reason', () {
    expect(
      () => parsePairingPayload('not-a-uri'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('not a URI'),
        ),
      ),
    );
  });

  test('malformed manual payload throws with malformed failure reason', () {
    expect(
      () => parseManualPairingPayload('totally-invalid'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('host'),
        ),
      ),
    );
  });

  test('explicit rejected poll state is surfaced', () {
    final simulator = _DeterministicPollSimulator({
      'REJECT': PairingPollState.rejected,
    });
    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: 'REJECT',
      claimedAt: DateTime.now(),
    );

    expect(simulator.simulatePoll(claim), PairingPollState.rejected);
  });

  test('explicit expired poll state is surfaced', () {
    final simulator = _DeterministicPollSimulator({
      'EXPIRE': PairingPollState.expired,
    });
    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: 'EXPIRE',
      claimedAt: DateTime.now(),
    );

    expect(simulator.simulatePoll(claim), PairingPollState.expired);
  });

  test('explicit revoked poll state is surfaced', () {
    final simulator = _DeterministicPollSimulator({
      'REVOKE': PairingPollState.revoked,
    });
    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: 'REVOKE',
      claimedAt: DateTime.now(),
    );

    expect(simulator.simulatePoll(claim), PairingPollState.revoked);
  });

  test('explicit unreachable poll state is surfaced', () {
    final simulator = _DeterministicPollSimulator({
      'UNREACH': PairingPollState.unreachable,
    });
    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: 'UNREACH',
      claimedAt: DateTime.now(),
    );

    expect(simulator.simulatePoll(claim), PairingPollState.unreachable);
  });

  test('poll pending stays pending when code is unknown', () {
    final simulator = _DeterministicPollSimulator({});
    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: 'UNKNOWN',
      claimedAt: DateTime.now(),
    );

    expect(simulator.simulatePoll(claim), PairingPollState.pending);
  });

  test('controller transitions through claim and poll to approved', () async {
    final store = _FakeSecureStore();
    final controller = PairingController(
      secureStore: store,
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPollSimulator({
        'WIN': PairingPollState.approved,
      }),
    );

    await controller.submitPayload(
      'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=WIN',
    );

    expect(controller.state.isTrusted, isTrue);
    expect(controller.state.trustMaterial, isNotNull);
    expect(controller.state.trustMaterial!.hostId, isNotEmpty);
    expect(controller.state.trustMaterial!.secret, isNotEmpty);

    final stored = await store.readTrustMaterial();
    expect(stored, isNotNull);
    expect(stored!.hostId, controller.state.trustMaterial!.hostId);
  });

  test(
    'controller can claim and poll through daemon pairing repository',
    () async {
      final store = _FakeSecureStore();
      final repository = _FakePairingClaimRepository.single(
        const PairingPollOutcome(
          pollState: PairingPollState.approved,
          trustMaterial: TrustMaterial(
            hostId: 'host_live',
            deviceId: 'device_live',
            secret: 'secret_live',
          ),
        ),
      );
      final controller = PairingController(
        secureStore: store,
        localAuth: _AllowingAuth(),
        claimRepository: repository,
      );

      await controller.submitPayload(
        'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=LIVE',
      );

      expect(repository.claims, hasLength(1));
      expect(repository.polls, hasLength(1));
      expect(controller.state.isTrusted, isTrue);
      expect(controller.state.trustMaterial!.hostId, 'host_live');
      expect((await store.readTrustMaterial())!.secret, 'secret_live');
    },
  );

  test(
    'controller keeps polling repository until host approval is available',
    () async {
      final store = _FakeSecureStore();
      final repository = _FakePairingClaimRepository([
        const PairingPollOutcome(pollState: PairingPollState.pending),
        const PairingPollOutcome(
          pollState: PairingPollState.approved,
          trustMaterial: TrustMaterial(
            hostId: 'host_live',
            deviceId: 'device_live',
            secret: 'secret_live',
          ),
        ),
      ]);
      final controller = PairingController(
        secureStore: store,
        localAuth: _AllowingAuth(),
        claimRepository: repository,
        repositoryPollInterval: Duration.zero,
        repositoryMaxPollAttempts: 2,
      );

      await controller.submitPayload(
        'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=LIVE',
      );

      expect(repository.polls, hasLength(2));
      expect(controller.state.isTrusted, isTrue);
      expect((await store.readTrustMaterial())!.deviceId, 'device_live');
    },
  );

  test(
    'controller surfaces rejected failure when poll returns rejected',
    () async {
      final controller = PairingController(
        secureStore: _FakeSecureStore(),
        localAuth: _AllowingAuth(),
        pollSimulator: _DeterministicPollSimulator({
          'FAIL': PairingPollState.rejected,
        }),
      );

      await controller.submitPayload(
        'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=FAIL',
      );

      expect(controller.state.isFailed, isTrue);
      expect(controller.state.failure, PairingFailure.rejectedByHost);
    },
  );

  test(
    'controller surfaces expired failure when poll returns expired',
    () async {
      final controller = PairingController(
        secureStore: _FakeSecureStore(),
        localAuth: _AllowingAuth(),
        pollSimulator: _DeterministicPollSimulator({
          'OLD': PairingPollState.expired,
        }),
      );

      await controller.submitPayload(
        'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=OLD',
      );

      expect(controller.state.isFailed, isTrue);
      expect(controller.state.failure, PairingFailure.expired);
    },
  );

  test(
    'controller surfaces revoked failure when poll returns revoked',
    () async {
      final controller = PairingController(
        secureStore: _FakeSecureStore(),
        localAuth: _AllowingAuth(),
        pollSimulator: _DeterministicPollSimulator({
          'RVK': PairingPollState.revoked,
        }),
      );

      await controller.submitPayload(
        'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=RVK',
      );

      expect(controller.state.isFailed, isTrue);
      expect(controller.state.failure, PairingFailure.revoked);
    },
  );

  test(
    'controller surfaces unreachable failure when poll returns unreachable',
    () async {
      final controller = PairingController(
        secureStore: _FakeSecureStore(),
        localAuth: _AllowingAuth(),
        pollSimulator: _DeterministicPollSimulator({
          'NET': PairingPollState.unreachable,
        }),
      );

      await controller.submitPayload(
        'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=NET',
      );

      expect(controller.state.isFailed, isTrue);
      expect(controller.state.failure, PairingFailure.unreachableHost);
    },
  );

  test('controller surfaces malformed failure on bad payload', () async {
    final controller = PairingController(
      secureStore: _FakeSecureStore(),
      localAuth: _AllowingAuth(),
      pollSimulator: _DeterministicPollSimulator({}),
    );

    await controller.submitPayload('not-a-valid-payload');

    expect(controller.state.isFailed, isTrue);
    expect(controller.state.failure, PairingFailure.malformedPayload);
  });

  test('secure write is blocked when local auth is denied', () async {
    final store = _FakeSecureStore();
    final controller = PairingController(
      secureStore: store,
      localAuth: _DenyingAuth(),
      pollSimulator: _DeterministicPollSimulator({
        'WIN': PairingPollState.approved,
      }),
    );

    await controller.submitPayload(
      'continuum://pair?host=http%3A%2F%2F127.0.0.1%3A8765&code=WIN',
    );

    expect(controller.state.isFailed, isTrue);
    expect(controller.state.failure, PairingFailure.localAuthDenied);

    final stored = await store.readTrustMaterial();
    expect(stored, isNull);
  });

  test('secure write gate delegates read without auth', () async {
    final inner = _FakeSecureStore();
    final gate = SecureWriteGate(store: inner, localAuth: _DenyingAuth());

    await inner.writeTrustMaterial(
      const TrustMaterial(hostId: 'h1', deviceId: 'd1', secret: 's1'),
    );

    final read = await gate.readTrustMaterial();
    expect(read, isNotNull);
    expect(read!.hostId, 'h1');
  });

  test('secure write gate blocks write when auth denies', () async {
    final inner = _FakeSecureStore();
    final gate = SecureWriteGate(store: inner, localAuth: _DenyingAuth());

    await gate.writeTrustMaterial(
      const TrustMaterial(hostId: 'h1', deviceId: 'd1', secret: 's1'),
    );

    final stored = await inner.readTrustMaterial();
    expect(stored, isNull);
  });

  test('secure write gate allows write when auth confirms', () async {
    final inner = _FakeSecureStore();
    final gate = SecureWriteGate(store: inner, localAuth: _AllowingAuth());

    await gate.writeTrustMaterial(
      const TrustMaterial(hostId: 'h1', deviceId: 'd1', secret: 's1'),
    );

    final stored = await inner.readTrustMaterial();
    expect(stored, isNotNull);
    expect(stored!.hostId, 'h1');
  });

  test('pairing result success carries trust material', () {
    const material = TrustMaterial(hostId: 'h1', deviceId: 'd1', secret: 's1');
    final result = PairingResult.success(material);

    expect(result.isSuccess, isTrue);
    expect(result.isFailure, isFalse);
    expect(result.trustMaterial, material);
    expect(result.failure, isNull);
  });

  test('pairing result failure carries failure reason', () {
    final result = PairingResult.failure(PairingFailure.rejectedByHost);

    expect(result.isSuccess, isFalse);
    expect(result.isFailure, isTrue);
    expect(result.trustMaterial, isNull);
    expect(result.failure, PairingFailure.rejectedByHost);
  });

  test('pairing screen state factory constructors are mutually exclusive', () {
    const idle = PairingScreenState.idle();
    expect(idle.isIdle, isTrue);
    expect(idle.isScanning, isFalse);
    expect(idle.isManualInput, isFalse);

    const scanning = PairingScreenState.scanning();
    expect(scanning.isScanning, isTrue);
    expect(scanning.isIdle, isFalse);

    const manual = PairingScreenState.manualInput();
    expect(manual.isManualInput, isTrue);

    final claim = PairingClaim(
      hostUrl: Uri.parse('http://127.0.0.1:8765'),
      code: '123',
      claimedAt: DateTime.now(),
    );
    final claiming = PairingScreenState.claiming(claim);
    expect(claiming.isClaiming, isTrue);
    expect(claiming.isIdle, isFalse);

    final polling = PairingScreenState.polling(claim, PairingPollState.pending);
    expect(polling.isPolling, isTrue);
    expect(polling.isClaiming, isFalse);

    const failed = PairingScreenState.failed(PairingFailure.expired);
    expect(failed.isFailed, isTrue);

    const trusted = PairingScreenState.trusted(
      TrustMaterial(hostId: 'h1', deviceId: 'd1', secret: 's1'),
    );
    expect(trusted.isTrusted, isTrue);
  });

  test(
    'daemon pairing repository claims pairing code over host endpoint',
    () async {
      final adapter = _RecordingAdapter(
        '{"claim_token":"claim_1","session_id":"pairing_1"}',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = DaemonPairingRepository(dio: dio);

      final ticket = await repository.claim(
        PairingPayload(
          hostUrl: Uri.parse('http://127.0.0.1:4890'),
          code: 'ABC-123',
        ),
        deviceLabel: 'QA phone',
        claimedAt: DateTime.utc(2026, 5, 25),
      );

      expect(ticket.claimToken, 'claim_1');
      expect(ticket.sessionId, 'pairing_1');
      expect(adapter.method, 'POST');
      expect(adapter.path, '/pairing/claim');
      expect(adapter.requestBody, contains('ABC-123'));
      expect(adapter.requestBody, contains('QA phone'));
    },
  );

  test('daemon pairing repository maps approved poll credentials', () async {
    final dio = Dio()
      ..httpClientAdapter = const _FakeAdapter(
        '{"status":"approved","credentials":{"device_id":"device_1","device_secret":"secret_1"}}',
      );
    final repository = DaemonPairingRepository(dio: dio);

    final result = await repository.poll(
      PairingClaimTicket(
        claim: PairingClaim(
          hostUrl: Uri.parse('http://127.0.0.1:4890'),
          code: 'ABC-123',
          claimedAt: DateTime.utc(2026, 5, 25),
        ),
        claimToken: 'claim_1',
        sessionId: 'pairing_1',
      ),
    );

    expect(result.pollState, PairingPollState.approved);
    expect(result.trustMaterial?.deviceId, 'device_1');
    expect(result.trustMaterial?.secret, 'secret_1');
  });

  test('daemon pairing repository maps rejected poll state', () async {
    final dio = Dio()
      ..httpClientAdapter = const _FakeAdapter('{"status":"rejected"}');
    final repository = DaemonPairingRepository(dio: dio);

    final result = await repository.poll(
      PairingClaimTicket(
        claim: PairingClaim(
          hostUrl: Uri.parse('http://127.0.0.1:4890'),
          code: 'ABC-123',
          claimedAt: DateTime.utc(2026, 5, 25),
        ),
        claimToken: 'claim_1',
        sessionId: 'pairing_1',
      ),
    );

    expect(result.pollState, PairingPollState.rejected);
    expect(result.failure, PairingFailure.rejectedByHost);
  });
}

class _FakeAdapter implements HttpClientAdapter {
  const _FakeAdapter(this.body);

  final String body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingAdapter extends _FakeAdapter {
  _RecordingAdapter(super.body);

  String method = '';
  String path = '';
  String requestBody = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.uri.path;
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    requestBody = String.fromCharCodes(chunks);
    return super.fetch(options, requestStream, cancelFuture);
  }
}
