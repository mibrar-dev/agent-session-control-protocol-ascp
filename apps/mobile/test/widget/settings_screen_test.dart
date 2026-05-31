import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/features/settings/application/settings_controller.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/trusted_device.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('settings screen renders trusted device label', (tester) async {
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: SettingsScreen()),
    );

    expect(find.text('Settings and trusted devices'), findsOneWidget);
  });

  testWidgets('settings screen renders trusted device inventory', (
    tester,
  ) async {
    final controller = SettingsController(
      repository: MemorySettingsRepository(
        devices: const [
          TrustedDevice.current(id: 'device_1', displayName: 'This phone'),
        ],
      ),
      localAuth: const AllowingLocalAuthGate(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SettingsScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('This phone'), findsOneWidget);
    expect(find.text('connected'), findsWidgets);
  });

  testWidgets('settings screen delegates revoke action', (tester) async {
    final repository = MemorySettingsRepository(
      devices: const [
        TrustedDevice(
          id: 'device_2',
          displayName: 'Old tablet',
          isCurrentDevice: false,
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SettingsScreen(
          controller: SettingsController(
            repository: repository,
            localAuth: const AllowingLocalAuthGate(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Revoke'));
    await tester.pump();

    expect(repository.revokedDeviceIds, ['device_2']);
  });

  testWidgets('settings screen does not render hardcoded Muhammad', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Muhammad'), findsNothing);
  });

  testWidgets('settings screen does not render hardcoded MacBook Pro · Local', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('MacBook Pro · Local'), findsNothing);
  });

  testWidgets('settings screen shows host id from diagnostics', (tester) async {
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Host: host_1'), findsOneWidget);
  });

  testWidgets('settings screen shows empty device state when no devices', (
    tester,
  ) async {
    final controller = SettingsController(
      repository: MemorySettingsRepository(devices: const []),
      localAuth: const AllowingLocalAuthGate(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SettingsScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('No trusted devices'), findsOneWidget);
  });
}
