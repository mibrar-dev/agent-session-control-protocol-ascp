import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android release manifest declares live mobile capabilities', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android.permission.INTERNET'),
      reason: 'Live ASCP HTTP and WebSocket transport needs network access.',
    );
    expect(
      manifest,
      contains('android.permission.CAMERA'),
      reason: 'Host pairing scans QR codes through mobile_scanner.',
    );
    expect(
      manifest,
      contains('android.permission.USE_BIOMETRIC'),
      reason: 'Local confirmation uses the platform biometric prompt.',
    );
    expect(manifest, contains('android:label="Continuum"'));
  });

  test('android activity supports local auth plugin requirements', () {
    final activity = File(
      'android/app/src/main/kotlin/app/continuum/mobile/MainActivity.kt',
    ).readAsStringSync();

    expect(activity, contains('FlutterFragmentActivity'));
  });

  test('ios info plist declares live mobile usage descriptions', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<string>Continuum</string>'));
    expect(plist, contains('<key>NSCameraUsageDescription</key>'));
    expect(
      plist,
      contains('Scan host pairing QR codes'),
      reason: 'iOS requires an explicit camera permission rationale.',
    );
    expect(plist, contains('<key>NSFaceIDUsageDescription</key>'));
    expect(
      plist,
      contains('Confirm trusted-device actions'),
      reason: 'iOS requires an explicit Face ID permission rationale.',
    );
  });

  test('ios runner supports simulator destinations', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(
      project,
      isNot(contains('SUPPORTED_PLATFORMS = iphoneos;')),
      reason: 'The Runner scheme must not be limited to physical iOS devices.',
    );
    expect(
      project,
      contains('SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";'),
      reason: 'Flutter run on iOS simulators needs iphonesimulator support.',
    );
  });
}
