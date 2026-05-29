import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/design_system/continuum_tokens.dart';
import '../application/pairing_controller.dart';
import '../domain/pairing_state.dart';

abstract interface class PairingScanner {
  Future<String?> scan(BuildContext context);
}

class PairingScreen extends StatefulWidget {
  const PairingScreen({
    required this.controller,
    required this.scanner,
    this.onContinue,
    super.key,
  });

  final PairingController controller;
  final PairingScanner scanner;
  final VoidCallback? onContinue;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    return Padding(
      padding: const EdgeInsets.all(ContinuumSpacingTokens.x5),
      child: Align(
        alignment: Alignment.topCenter,
        child: _PairingCard(child: _buildCardContent(state)),
      ),
    );
  }

  Widget _buildCardContent(PairingScreenState state) {
    if (_claiming) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StateLabel(label: 'Claiming'),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const Text('Claiming Device...', style: _titleStyle),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Spinner(),
              SizedBox(width: ContinuumSpacingTokens.x2),
              Flexible(
                child: Text(
                  'Establishing secure channel',
                  style: _bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          _ActionButton(
            label: 'Cancel',
            variant: _ButtonVariant.ghost,
            onTap: () {},
            enabled: false,
          ),
        ],
      );
    }

    if (state.isTrusted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StateLabel(
            label: 'Success',
            color: ContinuumColorTokens.success,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const _OutcomeIcon(label: 'OK', color: ContinuumColorTokens.success),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const Text(
            'Device Paired',
            style: _titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x2),
          const Text(
            'This device is now trusted on this host.',
            style: _subtleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          _ActionButton(
            label: 'Continue',
            variant: _ButtonVariant.primary,
            onTap: widget.onContinue ?? () {},
          ),
        ],
      );
    }

    if (state.isFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StateLabel(label: 'Error', color: ContinuumColorTokens.danger),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const _OutcomeIcon(label: 'X', color: ContinuumColorTokens.danger),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const Text(
            'Pairing Failed',
            style: _titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x2),
          Text(
            _failureLabel(state.failure),
            style: _subtleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          _ActionButton(
            label: 'Try again',
            variant: _ButtonVariant.danger,
            onTap: _resetToIdle,
          ),
        ],
      );
    }

    if (state.isManualInput) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StateLabel(label: 'Code Entry'),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const Text('Enter Pairing Code', style: _titleStyle),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          _ManualInput(
            controller: _textController,
            focusNode: _focusNode,
            onSubmitted: _submitManual,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const Text(
            'Enter the pairing code shown on your host.',
            style: _subtleStyle,
          ),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          Semantics(
            identifier: 'verify_button',
            child: _ActionButton(
              label: 'Verify',
              variant: _ButtonVariant.primary,
              onTap: _submitManual,
            ),
          ),
        ],
      );
    }

    if (state.isPolling) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StateLabel(label: 'Waiting'),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const Text('Waiting for host approval', style: _titleStyle),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Spinner(),
              SizedBox(width: ContinuumSpacingTokens.x2),
              Flexible(
                child: Text(
                  'Approve this device on the host to finish pairing.',
                  style: _bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: ContinuumSpacingTokens.x4),
          _ActionButton(
            label: 'Cancel',
            variant: _ButtonVariant.ghost,
            onTap: () => setState(widget.controller.cancel),
          ),
        ],
      );
    }

    if (state.isScanning) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            identifier: 'scanning_state',
            child: const _StateLabel(label: 'Scanning'),
          ),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          Semantics(
            identifier: 'pair_new_device_title',
            child: const Text('Pair New Device', style: _titleStyle),
          ),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          const _ScanArea(),
          const SizedBox(height: ContinuumSpacingTokens.x3),
          _ActionButton(
            label: 'Cancel',
            variant: _ButtonVariant.ghost,
            onTap: () => setState(widget.controller.cancel),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'scanning_state',
          child: const _StateLabel(label: 'Scanning'),
        ),
        const SizedBox(height: ContinuumSpacingTokens.x3),
        Semantics(
          identifier: 'pair_new_device_title',
          child: const Text('Pair New Device', style: _titleStyle),
        ),
        const SizedBox(height: ContinuumSpacingTokens.x3),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _scan,
          child: const _ScanArea(),
        ),
        const SizedBox(height: ContinuumSpacingTokens.x3),
        Semantics(
          identifier: 'enter_code_manually',
          child: _ActionButton(
            label: 'Enter code manually',
            variant: _ButtonVariant.ghost,
            onTap: () => setState(widget.controller.startManualInput),
          ),
        ),
      ],
    );
  }

  Future<void> _scan() async {
    setState(widget.controller.startScanning);
    final payload = await widget.scanner.scan(context);
    if (payload == null) {
      return;
    }
    await _submit(payload);
  }

  Future<void> _submitManual() {
    return _submit(_textController.text);
  }

  Future<void> _submit(String payload) async {
    setState(() => _claiming = true);
    await widget.controller.submitPayload(payload);
    if (mounted) {
      setState(() => _claiming = false);
    }
  }

  void _resetToIdle() {
    _textController.clear();
    _focusNode.unfocus();
    setState(widget.controller.cancel);
  }

  String _failureLabel(PairingFailure? failure) {
    return switch (failure) {
      PairingFailure.rejectedByHost => 'Rejected by host',
      PairingFailure.expired => 'Pairing code expired',
      PairingFailure.revoked => 'Pairing revoked',
      PairingFailure.unreachableHost => 'Host unreachable',
      PairingFailure.malformedPayload => 'Invalid pairing code',
      PairingFailure.localAuthDenied => 'Local authentication denied',
      null => 'Pairing failed',
    };
  }
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ContinuumColorTokens.bgElevated,
          border: Border.all(color: ContinuumColorTokens.border),
          borderRadius: BorderRadius.circular(ContinuumRadiusTokens.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ContinuumSpacingTokens.x4 - 2),
          child: child,
        ),
      ),
    );
  }
}

class _StateLabel extends StatelessWidget {
  const _StateLabel({
    required this.label,
    this.color = ContinuumColorTokens.accent,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanArea extends StatelessWidget {
  const _ScanArea();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContinuumColorTokens.bgSurface,
        border: Border.all(color: ContinuumColorTokens.border),
        borderRadius: BorderRadius.circular(ContinuumRadiusTokens.sm + 2),
      ),
      child: const SizedBox(
        height: 64,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QR', style: _monoMutedStyle),
              SizedBox(width: ContinuumSpacingTokens.x2),
              Text('Scan QR code', style: _subtleStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualInput extends StatelessWidget {
  const _ManualInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: ContinuumColorTokens.bgSurface,
            border: Border.all(
              color: focusNode.hasFocus
                  ? ContinuumColorTokens.accent
                  : ContinuumColorTokens.border,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: ContinuumColorTokens.accent.withValues(alpha: 0.2),
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: EditableText(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ContinuumColorTokens.textPrimary,
                fontSize: 18,
                height: 1.2,
                letterSpacing: 1.6,
                fontFamily: 'monospace',
              ),
              cursorColor: ContinuumColorTokens.accent,
              backgroundCursorColor: ContinuumColorTokens.border,
              maxLines: 1,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
        );
      },
    );
  }
}

enum _ButtonVariant { primary, ghost, danger }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.variant,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final _ButtonVariant variant;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      _ButtonVariant.primary => ContinuumColorTokens.accent,
      _ButtonVariant.ghost => ContinuumColorTokens.textPrimary,
      _ButtonVariant.danger => ContinuumColorTokens.danger,
    };
    final background = switch (variant) {
      _ButtonVariant.primary => ContinuumColorTokens.accent,
      _ButtonVariant.ghost => ContinuumColorTokens.bgElevated,
      _ButtonVariant.danger => ContinuumColorTokens.danger.withValues(
        alpha: 0.12,
      ),
    };
    final border = switch (variant) {
      _ButtonVariant.primary => ContinuumColorTokens.accent,
      _ButtonVariant.ghost => ContinuumColorTokens.border,
      _ButtonVariant.danger => ContinuumColorTokens.danger,
    };
    final textColor = variant == _ButtonVariant.primary
        ? ContinuumColorTokens.accentForeground
        : color;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeIcon extends StatelessWidget {
  const _OutcomeIcon({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(999),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ContinuumColorTokens.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: ContinuumColorTokens.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

const _bodyStyle = TextStyle(
  color: ContinuumColorTokens.textPrimary,
  fontSize: 12,
  height: 1.45,
);

const _subtleStyle = TextStyle(
  color: ContinuumColorTokens.mutedText,
  fontSize: 11,
  height: 1.4,
);

const _monoMutedStyle = TextStyle(
  color: ContinuumColorTokens.mutedText,
  fontSize: 12,
  fontFamily: 'monospace',
  fontWeight: FontWeight.w700,
);
