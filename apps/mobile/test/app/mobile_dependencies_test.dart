import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/mobile_dependencies.dart';
import 'package:mobile/features/approvals/data/approval_repository.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/core/security/secure_store.dart';
import 'package:mobile/features/inspect/data/inspect_repository.dart';
import 'package:mobile/features/sessions/data/session_repository.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';

void main() {
  test('memory dependencies keep deterministic in-memory controllers', () {
    final dependencies = MobileDependencies.memory();

    expect(
      dependencies.sessionListController.repository,
      isA<MemorySessionRepository>(),
    );
    expect(
      dependencies.approvalQueueController.repository,
      isA<MemoryApprovalRepository>(),
    );
    expect(
      dependencies.inspectController.repository,
      isA<MemoryInspectRepository>(),
    );
    expect(
      dependencies.settingsController.repository,
      isA<MemorySettingsRepository>(),
    );
  });

  test('live dependencies wire ASCP and daemon-backed repositories', () {
    final dependencies = MobileDependencies.live(
      rpcEndpoint: Uri.parse('http://127.0.0.1:18787/rpc'),
      websocketEndpoint: Uri.parse('ws://127.0.0.1:18787/rpc'),
      daemonAdminBaseUrl: Uri.parse('http://127.0.0.1:18787'),
      hostId: 'host_local',
      activeSessionId: 'sess_active',
      currentDeviceId: 'device_mobile',
    );

    expect(
      dependencies.sessionListController.repository,
      isA<AscpSessionRepository>(),
    );
    expect(
      dependencies.approvalQueueController.repository,
      isA<AscpApprovalRepository>(),
    );
    expect(
      dependencies.inspectController.repository,
      isA<AscpInspectRepository>(),
    );
    expect(
      dependencies.settingsController.repository,
      isA<DaemonSettingsRepository>(),
    );
    expect(
      dependencies.settingsController.localAuth,
      isA<DeviceLocalAuthGate>(),
    );
    expect(dependencies.pairingController.store, isA<FlutterSecureStore>());
    expect(dependencies.hostId, 'host_local');
    expect(dependencies.activeSessionId, 'sess_active');
  });
}
