import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec describes the Continuum mobile companion', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, isNot(contains('A new Flutter project.')));
    expect(
      pubspec,
      contains('Continuum ASCP mobile companion'),
      reason: 'Package metadata should identify the app, not the scaffold.',
    );
  });

  test('android gradle config has intentional release metadata notes', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, isNot(contains('TODO:')));
    expect(gradle, contains('applicationId = "app.continuum.mobile"'));
    expect(gradle, contains('Continuum production releases'));
  });

  test('web metadata identifies Continuum instead of scaffold defaults', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();

    expect(index, isNot(contains('A new Flutter project.')));
    expect(index, contains('<title>Continuum</title>'));
    expect(index, contains('apple-mobile-web-app-title" content="Continuum"'));
    expect(manifest, isNot(contains('A new Flutter project.')));
    expect(manifest, contains('"name": "Continuum"'));
    expect(manifest, contains('"short_name": "Continuum"'));
  });
}
