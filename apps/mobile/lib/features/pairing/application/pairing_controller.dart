import '../../../core/security/local_auth_gate.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/security/trust_material.dart';
import '../data/pairing_repository.dart';
import '../domain/pairing_state.dart';

class PairingController {
  PairingController({
    required SecureStore secureStore,
    required LocalAuthGate localAuth,
    this.pollSimulator,
    this.claimRepository,
    this.repositoryPollInterval = const Duration(seconds: 1),
    this.repositoryMaxPollAttempts = 60,
    DateTime Function()? now,
  }) : assert(
         pollSimulator != null || claimRepository != null,
         'PairingController requires a simulator or claim repository.',
       ),
       secureStore = SecureWriteGate(store: secureStore, localAuth: localAuth),
       _now = now ?? DateTime.now;

  final SecureWriteGate secureStore;
  final PairingPollSimulator? pollSimulator;
  final PairingClaimRepository? claimRepository;
  final Duration repositoryPollInterval;
  final int repositoryMaxPollAttempts;
  final DateTime Function() _now;

  SecureStore get store => secureStore.store;

  PairingScreenState state = const PairingScreenState.idle();

  void startScanning() {
    state = const PairingScreenState.scanning();
  }

  void startManualInput() {
    state = const PairingScreenState.manualInput();
  }

  void cancel() {
    state = const PairingScreenState.idle();
  }

  Future<void> submitPayload(String rawPayload) async {
    try {
      final payload = parsePairingPayload(rawPayload);
      await submitParsedPayload(payload);
    } on FormatException {
      try {
        final payload = parseManualPairingPayload(rawPayload);
        await submitParsedPayload(payload);
      } on FormatException {
        state = const PairingScreenState.failed(
          PairingFailure.malformedPayload,
        );
      }
    }
  }

  Future<void> submitParsedPayload(PairingPayload payload) async {
    final repository = claimRepository;
    if (repository != null) {
      await _submitThroughRepository(payload, repository);
      return;
    }

    final claim = PairingClaim(
      hostUrl: payload.hostUrl,
      code: payload.code,
      claimedAt: _now(),
    );
    state = PairingScreenState.claiming(claim);

    final pollState = pollSimulator!.simulatePoll(claim);
    state = PairingScreenState.polling(claim, pollState);

    await _applyPollOutcome(
      claim: claim,
      outcome: PairingPollOutcome(
        pollState: pollState,
        trustMaterial: pollState == PairingPollState.approved
            ? deriveTrustMaterialFromApprovedClaim(claim)
            : null,
      ),
    );
  }

  Future<void> _submitThroughRepository(
    PairingPayload payload,
    PairingClaimRepository repository,
  ) async {
    try {
      final ticket = await repository.claim(
        payload,
        deviceLabel: 'Continuum Mobile',
        claimedAt: _now(),
      );
      state = PairingScreenState.claiming(ticket.claim);
      var outcome = await repository.poll(ticket);
      state = PairingScreenState.polling(ticket.claim, outcome.pollState);
      for (
        var attempt = 1;
        outcome.pollState == PairingPollState.pending &&
            attempt < repositoryMaxPollAttempts;
        attempt += 1
      ) {
        if (repositoryPollInterval > Duration.zero) {
          await Future<void>.delayed(repositoryPollInterval);
        }
        outcome = await repository.poll(ticket);
        state = PairingScreenState.polling(ticket.claim, outcome.pollState);
      }
      await _applyPollOutcome(claim: ticket.claim, outcome: outcome);
    } on Object {
      state = const PairingScreenState.failed(PairingFailure.unreachableHost);
    }
  }

  Future<void> _applyPollOutcome({
    required PairingClaim claim,
    required PairingPollOutcome outcome,
  }) async {
    switch (outcome.pollState) {
      case PairingPollState.pending:
        return;
      case PairingPollState.approved:
        final material =
            outcome.trustMaterial ??
            deriveTrustMaterialFromApprovedClaim(claim);
        final written = await secureStore.writeTrustMaterial(material);
        state = written
            ? PairingScreenState.trusted(material)
            : const PairingScreenState.failed(PairingFailure.localAuthDenied);
      case PairingPollState.rejected:
        state = const PairingScreenState.failed(PairingFailure.rejectedByHost);
      case PairingPollState.expired:
        state = const PairingScreenState.failed(PairingFailure.expired);
      case PairingPollState.revoked:
        state = const PairingScreenState.failed(PairingFailure.revoked);
      case PairingPollState.unreachable:
        state = const PairingScreenState.failed(PairingFailure.unreachableHost);
    }
  }
}

class SecureWriteGate {
  const SecureWriteGate({required this.store, required this.localAuth});

  final SecureStore store;
  final LocalAuthGate localAuth;

  Future<TrustMaterial?> readTrustMaterial() {
    return store.readTrustMaterial();
  }

  Future<bool> writeTrustMaterial(TrustMaterial material) async {
    final confirmed = await localAuth.confirm('Store trusted host credentials');
    if (!confirmed) {
      return false;
    }
    await store.writeTrustMaterial(material);
    return true;
  }
}
