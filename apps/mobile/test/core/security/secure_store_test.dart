import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/secure_store.dart';
import 'package:mobile/core/security/trust_material.dart';

void main() {
  test(
    'flutter secure store writes trust material as one JSON value',
    () async {
      final driver = _MemorySecureStorageDriver();
      final store = FlutterSecureStore(driver: driver);

      await store.writeTrustMaterial(
        const TrustMaterial(
          hostId: 'host_1',
          deviceId: 'device_1',
          secret: 'secret_1',
        ),
      );

      expect(driver.values.keys, ['continuum.trust_material']);
      expect(
        driver.values['continuum.trust_material'],
        contains('"host_id":"host_1"'),
      );
      expect(
        driver.values['continuum.trust_material'],
        contains('"device_id":"device_1"'),
      );
      expect(
        driver.values['continuum.trust_material'],
        contains('"secret":"secret_1"'),
      );
    },
  );

  test('flutter secure store reads stored trust material', () async {
    final driver = _MemorySecureStorageDriver();
    final store = FlutterSecureStore(driver: driver);

    await store.writeTrustMaterial(
      const TrustMaterial(
        hostId: 'host_2',
        deviceId: 'device_2',
        secret: 'secret_2',
      ),
    );

    final material = await store.readTrustMaterial();

    expect(material, isNotNull);
    expect(material!.hostId, 'host_2');
    expect(material.deviceId, 'device_2');
    expect(material.secret, 'secret_2');
  });

  test('flutter secure store ignores malformed trust material', () async {
    final driver = _MemorySecureStorageDriver()
      ..values['continuum.trust_material'] = '{"host_id":"missing fields"}';
    final store = FlutterSecureStore(driver: driver);

    final material = await store.readTrustMaterial();

    expect(material, isNull);
  });
}

class _MemorySecureStorageDriver implements SecureStorageDriver {
  final values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
