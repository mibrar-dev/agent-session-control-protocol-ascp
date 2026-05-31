import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/local_auth_gate.dart';
import 'package:mobile/features/settings/application/settings_controller.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/trusted_device.dart';
import 'package:mobile/features/settings/presentation/devices_screen.dart';

void main() {
  testWidgets('empty devices shows empty state, not demo devices', (
    tester,
  ) async {
    final controller = SettingsController(
      repository: MemorySettingsRepository(devices: const []),
      localAuth: const AllowingLocalAuthGate(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DevicesScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('No trusted devices paired'), findsOneWidget);
    expect(find.text('MacBook Pro · Local'), findsNothing);
    expect(find.text('Ubuntu Workstation'), findsNothing);
    expect(find.text('0 paired hosts'), findsOneWidget);
  });

  testWidgets('devices screen renders live device data', (tester) async {
    final controller = SettingsController(
      repository: MemorySettingsRepository(
        devices: const [
          TrustedDevice.current(id: 'd1', displayName: 'My iPhone'),
        ],
      ),
      localAuth: const AllowingLocalAuthGate(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DevicesScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('My iPhone'), findsOneWidget);
    expect(find.text('1 paired hosts'), findsOneWidget);
    expect(find.text('No trusted devices paired'), findsNothing);
  });
}
