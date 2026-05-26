import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'trust_material.dart';

abstract interface class SecureStore {
  Future<void> writeTrustMaterial(TrustMaterial material);

  Future<TrustMaterial?> readTrustMaterial();
}

abstract interface class SecureStorageDriver {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore({
    SecureStorageDriver driver = const FlutterSecureStorageDriver(),
    this.key = 'continuum.trust_material',
  }) : _driver = driver;

  final SecureStorageDriver _driver;
  final String key;

  @override
  Future<TrustMaterial?> readTrustMaterial() async {
    final value = await _driver.read(key: key);
    if (value == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        return null;
      }
      final json = Map<String, Object?>.from(decoded);
      final hostId = json['host_id'];
      final deviceId = json['device_id'];
      final secret = json['secret'];
      if (hostId is! String || deviceId is! String || secret is! String) {
        return null;
      }
      return TrustMaterial(hostId: hostId, deviceId: deviceId, secret: secret);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeTrustMaterial(TrustMaterial material) {
    return _driver.write(
      key: key,
      value: jsonEncode({
        'host_id': material.hostId,
        'device_id': material.deviceId,
        'secret': material.secret,
      }),
    );
  }
}

class FlutterSecureStorageDriver implements SecureStorageDriver {
  const FlutterSecureStorageDriver({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

class MemorySecureStore implements SecureStore {
  TrustMaterial? _material;

  @override
  Future<TrustMaterial?> readTrustMaterial() async => _material;

  @override
  Future<void> writeTrustMaterial(TrustMaterial material) async {
    _material = material;
  }
}
