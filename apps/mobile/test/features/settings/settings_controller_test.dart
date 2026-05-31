import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/features/settings/application/settings_controller.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/transport_diagnostics.dart';
import 'package:mobile/features/settings/domain/trusted_device.dart';

class _AuthGate implements LocalAuthGate {
  const _AuthGate(this.allowed);

  final bool allowed;

  @override
  Future<bool> confirm(String reason) async => allowed;
}

void main() {
  test('current device revoke requires biometric confirmation', () {
    final device = TrustedDevice.current(
      id: 'device_1',
      displayName: 'This iPhone',
    );

    expect(device.requiresLocalAuthForRevoke, isTrue);
  });

  test('settings controller lists trusted devices', () async {
    final controller = SettingsController(
      repository: MemorySettingsRepository(
        devices: const [
          TrustedDevice.current(id: 'device_1', displayName: 'This iPhone'),
        ],
      ),
      localAuth: const _AuthGate(true),
    );

    final devices = await controller.listTrustedDevices();

    expect(devices.single.displayName, 'This iPhone');
  });

  test('current device revoke requires local auth confirmation', () async {
    final repository = MemorySettingsRepository();
    final controller = SettingsController(
      repository: repository,
      localAuth: const _AuthGate(false),
    );

    final revoked = await controller.revokeDevice(
      const TrustedDevice.current(id: 'device_1', displayName: 'This iPhone'),
    );

    expect(revoked, isFalse);
    expect(repository.revokedDeviceIds, isEmpty);
  });

  test('non-current device revoke delegates directly', () async {
    final repository = MemorySettingsRepository();
    final controller = SettingsController(
      repository: repository,
      localAuth: const _AuthGate(false),
    );

    final revoked = await controller.revokeDevice(
      const TrustedDevice(
        id: 'device_2',
        displayName: 'iPad',
        isCurrentDevice: false,
      ),
    );

    expect(revoked, isTrue);
    expect(repository.revokedDeviceIds, ['device_2']);
  });

  test('transport diagnostics marks replay gaps as degraded', () {
    const diagnostics = TransportDiagnostics(
      hostId: 'host_1',
      state: 'connected',
      replayEnabled: false,
    );

    expect(diagnostics.isDegraded, isTrue);
  });

  test('daemon settings repository maps trusted devices', () async {
    final dio = Dio()
      ..httpClientAdapter = const _FakeAdapter(
        '{"devices":[{"deviceId":"device_1","displayName":"QA phone","revoked":false},{"device_id":"device_2","display_name":"Old phone","revoked":true}]}',
      );
    final repository = DaemonSettingsRepository(
      dio: dio,
      adminBaseUrl: Uri.parse('http://127.0.0.1:4890'),
      currentDeviceId: 'device_1',
    );

    final devices = await repository.listTrustedDevices();

    expect(devices.map((device) => device.id), ['device_1']);
    expect(devices.single.displayName, 'QA phone');
    expect(devices.single.isCurrentDevice, isTrue);
  });

  test('daemon settings repository delegates trusted device revoke', () async {
    final adapter = _RecordingAdapter(
      '{"device_id":"device_2","revoked":true}',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = DaemonSettingsRepository(
      dio: dio,
      adminBaseUrl: Uri.parse('http://127.0.0.1:4890'),
    );

    await repository.revokeTrustedDevice('device_2');

    expect(adapter.method, 'POST');
    expect(adapter.path, '/admin/trusted-devices/device_2/revoke');
  });

  test(
    'daemon settings repository reads live diagnostics from endpoint',
    () async {
      final dio = Dio()
        ..httpClientAdapter = const _FakeAdapter(
          '{"host_id":"host_abc","state":"connected","replay_enabled":true}',
        );
      final repository = DaemonSettingsRepository(
        dio: dio,
        adminBaseUrl: Uri.parse('http://127.0.0.1:4890'),
      );

      final diagnostics = await repository.readDiagnostics();

      expect(diagnostics.hostId, 'host_abc');
      expect(diagnostics.state, 'connected');
      expect(diagnostics.replayEnabled, isTrue);
      expect(diagnostics.isDegraded, isFalse);
    },
  );

  test(
    'daemon settings repository returns unreachable on network error',
    () async {
      final dio = Dio()..httpClientAdapter = const _ErrorAdapter();
      final repository = DaemonSettingsRepository(
        dio: dio,
        adminBaseUrl: Uri.parse('http://127.0.0.1:4890'),
      );

      final diagnostics = await repository.readDiagnostics();

      expect(diagnostics.state, 'unreachable');
      expect(diagnostics.isDegraded, isTrue);
    },
  );
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.uri.path;
    return super.fetch(options, requestStream, cancelFuture);
  }
}

class _ErrorAdapter implements HttpClientAdapter {
  const _ErrorAdapter();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }
}
