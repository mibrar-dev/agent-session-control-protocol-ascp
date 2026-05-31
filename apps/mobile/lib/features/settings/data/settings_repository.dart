import 'package:dio/dio.dart';

import '../domain/transport_diagnostics.dart';
import '../domain/trusted_device.dart';

abstract interface class SettingsRepository {
  Future<List<TrustedDevice>> listTrustedDevices();

  Future<void> revokeTrustedDevice(String deviceId);

  Future<TransportDiagnostics> readDiagnostics();
}

class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository({
    List<TrustedDevice> devices = const [],
    this.diagnostics = const TransportDiagnostics(
      hostId: 'host_1',
      state: 'connected',
      replayEnabled: true,
    ),
  }) : _devices = [...devices];

  final List<TrustedDevice> _devices;
  final TransportDiagnostics diagnostics;
  final List<String> revokedDeviceIds = [];

  @override
  Future<List<TrustedDevice>> listTrustedDevices() async => [..._devices];

  @override
  Future<TransportDiagnostics> readDiagnostics() async => diagnostics;

  @override
  Future<void> revokeTrustedDevice(String deviceId) async {
    revokedDeviceIds.add(deviceId);
  }
}

class DaemonSettingsRepository implements SettingsRepository {
  const DaemonSettingsRepository({
    required Dio dio,
    required this.adminBaseUrl,
    this.currentDeviceId,
  }) : _dio = dio;

  final Dio _dio;
  final Uri adminBaseUrl;
  final String? currentDeviceId;

  @override
  Future<List<TrustedDevice>> listTrustedDevices() async {
    final response = await _dio.getUri<Object?>(
      adminBaseUrl.resolve('/admin/trusted-devices'),
    );
    final body = _asMap(response.data, 'trusted devices');
    final devices = body['devices'];
    if (devices is! List) {
      throw const FormatException('Trusted devices response requires devices.');
    }

    return devices
        .whereType<Map>()
        .map((device) => _mapDevice(Map<String, Object?>.from(device)))
        .where((device) => device != null)
        .cast<TrustedDevice>()
        .toList(growable: false);
  }

  @override
  Future<TransportDiagnostics> readDiagnostics() async {
    try {
      final response = await _dio.getUri<Object?>(
        adminBaseUrl.resolve('/admin/diagnostics'),
      );
      final body = _asMap(response.data, 'diagnostics');
      return TransportDiagnostics(
        hostId: (body['host_id'] as String?) ?? 'unknown',
        state: (body['state'] as String?) ?? 'unknown',
        replayEnabled: body['replay_enabled'] == true,
        lastError: body['last_error'] as String?,
      );
    } on DioException {
      return const TransportDiagnostics(
        hostId: 'unknown',
        state: 'unreachable',
        replayEnabled: false,
      );
    }
  }

  @override
  Future<void> revokeTrustedDevice(String deviceId) async {
    await _dio.postUri<Object?>(
      adminBaseUrl.resolve(
        '/admin/trusted-devices/${Uri.encodeComponent(deviceId)}/revoke',
      ),
      data: const {},
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  TrustedDevice? _mapDevice(Map<String, Object?> device) {
    final revoked = device['revoked'];
    if (revoked == true) {
      return null;
    }

    final id = device['deviceId'] ?? device['device_id'];
    final displayName = device['displayName'] ?? device['display_name'];
    if (id is! String || displayName is! String) {
      throw const FormatException(
        'Trusted device requires id and display name.',
      );
    }

    return TrustedDevice(
      id: id,
      displayName: displayName,
      isCurrentDevice: currentDeviceId == id,
    );
  }
}

Map<String, Object?> _asMap(Object? value, String context) {
  if (value is! Map) {
    throw FormatException('Expected $context response object.');
  }
  return Map<String, Object?>.from(value);
}
