import 'package:flutter/widgets.dart';

import '../../../core/design_system/continuum_tokens.dart';
import '../../../core/security/local_auth_gate.dart';
import '../application/settings_controller.dart';
import '../data/settings_repository.dart';
import '../domain/trusted_device.dart';

class DevicesScreen extends StatelessWidget {
  DevicesScreen({SettingsController? controller, super.key})
    : controller =
          controller ??
          SettingsController(
            repository: MemorySettingsRepository(),
            localAuth: const AllowingLocalAuthGate(),
          );

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrustedDevice>>(
      future: controller.listTrustedDevices(),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const <TrustedDevice>[];
        return ColoredBox(
          color: SessionColors.pageBackground,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trusted devices',
                          style: TextStyle(
                            color: SessionColors.textDark,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${devices.length} paired hosts',
                          style: const TextStyle(
                            color: SessionColors.textMuted,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _AddButton(),
                ],
              ),
              const SizedBox(height: 28),
              if (devices.isEmpty)
                const _EmptyState()
              else
                for (final entry in devices.indexed) ...[
                  _DeviceCard(
                    device: entry.$2,
                    isOnline: entry.$2.isCurrentDevice,
                    platform: 'Device',
                    trustLabel: 'Trusted',
                  ),
                  const SizedBox(height: 16),
                ],
              const _TrustNote(),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isOnline,
    required this.platform,
    required this.trustLabel,
  });

  final TrustedDevice device;
  final bool isOnline;
  final String platform;
  final String trustLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SessionColors.cardSurface,
        border: Border.all(color: SessionColors.borderCard),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                _DeviceGlyph(platform: platform),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SessionColors.textDark,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [_PlatformPill(label: platform)],
                      ),
                    ],
                  ),
                ),
                const Text(
                  '›',
                  style: TextStyle(
                    color: SessionColors.textTertiary,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: SessionColors.borderLight),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isOnline ? '● Online' : '● Offline',
                    style: TextStyle(
                      color: isOnline
                          ? const Color(0xFF47785C)
                          : SessionColors.textMuted,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _TrustPill(label: trustLabel, trusted: trustLabel == 'Trusted'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceGlyph extends StatelessWidget {
  const _DeviceGlyph({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8DE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const SizedBox(
        width: 66,
        height: 66,
        child: Center(
          child: Text(
            '⌘',
            style: TextStyle(
              color: SessionColors.textSecondary,
              fontSize: 31,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SessionColors.textDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const SizedBox(
        width: 58,
        height: 58,
        child: Center(
          child: Text(
            '+',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformPill extends StatelessWidget {
  const _PlatformPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E9),
        border: Border.all(color: SessionColors.borderLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: SessionColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.label, required this.trusted});

  final String label;
  final bool trusted;

  @override
  Widget build(BuildContext context) {
    final color = trusted ? const Color(0xFF47785C) : const Color(0xFF9A6724);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No trusted devices paired',
          style: TextStyle(color: SessionColors.textMuted, fontSize: 17),
        ),
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        border: Border.all(color: const Color(0xFFE8D9C5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '♢',
              style: TextStyle(
                color: Color(0xFFB18455),
                fontSize: 31,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust is device-specific',
                    style: TextStyle(
                      color: SessionColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Revoking a host immediately blocks new sessions and approval requests from that device.',
                    style: TextStyle(
                      color: SessionColors.textMuted,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
