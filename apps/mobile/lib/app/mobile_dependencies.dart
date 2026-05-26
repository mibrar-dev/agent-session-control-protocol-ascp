import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/network/http_json_rpc_client.dart';
import '../core/network/websocket_json_rpc_client.dart';
import '../core/security/local_auth_gate.dart';
import '../core/security/secure_store.dart';
import '../features/approvals/application/approval_queue_controller.dart';
import '../features/approvals/data/approval_repository.dart';
import '../features/inspect/application/inspect_controller.dart';
import '../features/inspect/data/inspect_repository.dart';
import '../features/pairing/application/pairing_controller.dart';
import '../features/pairing/data/pairing_repository.dart';
import '../features/pairing/presentation/mobile_scanner_pairing_scanner.dart';
import '../features/pairing/presentation/pairing_screen.dart';
import '../features/sessions/application/session_list_controller.dart';
import '../features/sessions/data/session_repository.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/data/settings_repository.dart';

class MobileDependencies {
  const MobileDependencies({
    required this.hostId,
    required this.activeSessionId,
    required this.sessionListController,
    required this.approvalQueueController,
    required this.inspectController,
    required this.settingsController,
    required this.pairingController,
    required this.pairingScanner,
    required this.createSessionSubscriptionRepository,
  });

  factory MobileDependencies.memory({
    String hostId = 'host_1',
    String activeSessionId = 'session_1',
    SessionListController? sessionListController,
    ApprovalQueueController? approvalQueueController,
    InspectController? inspectController,
    SettingsController? settingsController,
    PairingController? pairingController,
    PairingScanner? pairingScanner,
    SessionSubscriptionRepository Function()?
    createSessionSubscriptionRepository,
  }) {
    return MobileDependencies(
      hostId: hostId,
      activeSessionId: activeSessionId,
      sessionListController:
          sessionListController ??
          SessionListController(repository: MemorySessionRepository()),
      approvalQueueController:
          approvalQueueController ??
          ApprovalQueueController(repository: MemoryApprovalRepository()),
      inspectController:
          inspectController ??
          InspectController(repository: MemoryInspectRepository()),
      settingsController:
          settingsController ??
          SettingsController(
            repository: MemorySettingsRepository(),
            localAuth: const AllowingLocalAuthGate(),
          ),
      pairingController:
          pairingController ??
          PairingController(
            secureStore: MemorySecureStore(),
            localAuth: const AllowingLocalAuthGate(),
            pollSimulator: const DeterministicPairingPollSimulator(),
          ),
      pairingScanner: pairingScanner ?? const MobileScannerPairingScanner(),
      createSessionSubscriptionRepository:
          createSessionSubscriptionRepository ??
          () => _UnsupportedSessionSubscriptionRepository(),
    );
  }

  factory MobileDependencies.live({
    required Uri rpcEndpoint,
    required Uri websocketEndpoint,
    required Uri daemonAdminBaseUrl,
    required String hostId,
    required String activeSessionId,
    String? currentDeviceId,
    Dio? dio,
    LocalAuthGate? localAuth,
    SecureStore secureStore = const FlutterSecureStore(),
  }) {
    final sharedDio = dio ?? Dio();
    final resolvedLocalAuth = localAuth ?? DeviceLocalAuthGate();
    final ascpClient = HttpJsonRpcClient(dio: sharedDio, endpoint: rpcEndpoint);

    return MobileDependencies(
      hostId: hostId,
      activeSessionId: activeSessionId,
      sessionListController: SessionListController(
        repository: AscpSessionRepository(client: ascpClient),
      ),
      approvalQueueController: ApprovalQueueController(
        repository: AscpApprovalRepository(client: ascpClient),
      ),
      inspectController: InspectController(
        repository: AscpInspectRepository(
          client: ascpClient,
          sessionId: activeSessionId,
        ),
      ),
      settingsController: SettingsController(
        repository: DaemonSettingsRepository(
          dio: sharedDio,
          adminBaseUrl: daemonAdminBaseUrl,
          currentDeviceId: currentDeviceId,
        ),
        localAuth: resolvedLocalAuth,
      ),
      pairingController: PairingController(
        secureStore: secureStore,
        localAuth: resolvedLocalAuth,
        claimRepository: DaemonPairingRepository(dio: sharedDio),
      ),
      pairingScanner: const MobileScannerPairingScanner(),
      createSessionSubscriptionRepository: () =>
          AscpSessionSubscriptionRepository(
            client: WebSocketJsonRpcClient(
              channel: WebSocketChannel.connect(websocketEndpoint),
            ),
          ),
    );
  }

  final String hostId;
  final String activeSessionId;
  final SessionListController sessionListController;
  final ApprovalQueueController approvalQueueController;
  final InspectController inspectController;
  final SettingsController settingsController;
  final PairingController pairingController;
  final PairingScanner pairingScanner;
  final SessionSubscriptionRepository Function()
  createSessionSubscriptionRepository;
}

class _UnsupportedSessionSubscriptionRepository
    implements SessionSubscriptionRepository {
  @override
  Future<SessionEventSubscription> subscribeTimeline({
    required String sessionId,
    int? fromSequence,
  }) {
    throw UnsupportedError('Live session subscriptions are not configured.');
  }
}
