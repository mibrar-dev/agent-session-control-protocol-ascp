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
    final screenHeight = MediaQuery.maybeSizeOf(context)?.height ?? 600;
    final compact = screenHeight < 700;
    return ColoredBox(
      color: const Color(0xFF100D08),
      child: ListView(
        padding: EdgeInsets.fromLTRB(28, compact ? 12 : 24, 28, 30),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[const _BackPlate(), const SizedBox(width: 20)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pair a host',
                      style: TextStyle(
                        color: const Color(0xFFF9F2EA),
                        fontSize: compact ? 30 : 39,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isTrusted
                          ? 'This device is now approved by the host.'
                          : 'Scan the QR code shown in Sessio Bridge or enter the pairing code manually.',
                      style: const TextStyle(
                        color: Color(0xFF9D9286),
                        fontSize: 18,
                        height: 1.28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 34),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _scan,
            child: _ScannerFrame(height: compact ? 180 : 360),
          ),
          SizedBox(height: compact ? 12 : 34),
          const _OrDivider(),
          SizedBox(height: compact ? 12 : 30),
          _CodeEntry(
            controller: _textController,
            focusNode: _focusNode,
            onSubmitted: _submitManual,
            boxHeight: compact ? 48 : 78,
          ),
          SizedBox(height: compact ? 12 : 28),
          ListenableBuilder(
            listenable: _textController,
            builder: (context, _) {
              return _ClaimButton(
                label: state.isTrusted
                    ? 'Continue'
                    : _claiming
                    ? 'Claiming device'
                    : 'Claim device',
                enabled: true,
                height: compact ? 52 : 72,
                onTap: state.isTrusted
                    ? (widget.onContinue ?? () {})
                    : _submitManual,
              );
            },
          ),
          SizedBox(height: compact ? 12 : 36),
          Center(
            child: Text(
              _statusLabel(state),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: state.isFailed
                    ? ContinuumColorTokens.danger
                    : const Color(0xFF9D9286),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 24),
            const Text(
              'Only approve hosts you recognize. Sessio never pairs without confirmation on the host machine.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A7F73),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 18),
          Center(
            child: GestureDetector(
              onTap: () => setState(widget.controller.startManualInput),
              child: const Text(
                'Enter code manually',
                style: TextStyle(
                  color: Color(0xFFC47C50),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
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
    if (payload.trim().isEmpty) {
      setState(widget.controller.startManualInput);
      _focusNode.requestFocus();
      return;
    }
    setState(() => _claiming = true);
    await widget.controller.submitPayload(payload);
    if (mounted) {
      setState(() => _claiming = false);
    }
  }

  String _statusLabel(PairingScreenState state) {
    if (_claiming || state.isPolling) {
      return '● Waiting for host approval...';
    }
    if (state.isTrusted) {
      return '● Host approved this device.';
    }
    if (state.isFailed) {
      return _failureLabel(state.failure);
    }
    return '● Waiting for host approval...';
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

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0906),
        border: Border.all(color: const Color(0xFF2A221B)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: SizedBox(
        height: height,
        child: Stack(
          children: const [
            Positioned.fill(child: _ScannerCorners()),
            Center(child: _ScanBeam()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: Text(
                'Align QR code within frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9D9286),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Text(
                'Scan QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4F463D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerPainter());
  }
}

class _ScanBeam extends StatelessWidget {
  const _ScanBeam();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF75E8F2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75E8F2).withValues(alpha: 0.70),
            blurRadius: 22,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const SizedBox(width: 270, height: 3),
    );
  }
}

class _CodeEntry extends StatefulWidget {
  const _CodeEntry({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.boxHeight,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final double boxHeight;

  @override
  State<_CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<_CodeEntry> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.replaceAll(RegExp(r'\s+'), '');
    final focusIndex = code.length.clamp(0, 5).toInt();
    return Stack(
      children: [
        Opacity(
          opacity: 0.01,
          child: EditableText(
            controller: widget.controller,
            focusNode: widget.focusNode,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            cursorColor: const Color(0xFFC47C50),
            backgroundCursorColor: const Color(0xFF4E463D),
            maxLines: 1,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(64)],
            onSubmitted: (_) => widget.onSubmitted(),
          ),
        ),
        GestureDetector(
          onTap: widget.focusNode.requestFocus,
          child: Row(
            children: [
              for (var index = 0; index < 6; index++) ...[
                Expanded(
                  child: _CodeBox(
                    height: widget.boxHeight,
                    value: index < code.length
                        ? code[index].toUpperCase()
                        : '—',
                    focused: widget.focusNode.hasFocus && index == focusIndex,
                  ),
                ),
                if (index < 5) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _onChanged() => setState(() {});
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.value,
    required this.focused,
    required this.height,
  });

  final String value;
  final bool focused;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15110D),
        border: Border.all(
          color: focused ? const Color(0xFFC47C50) : const Color(0xFF41372F),
          width: focused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        height: height,
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF665B50),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.height,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFC47C50) : const Color(0xFF494039),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: enabled
                    ? const Color(0xFF150E08)
                    : const Color(0xFF9D9286),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0xFF4B4239)),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'or enter code',
            style: TextStyle(
              color: Color(0xFF9D9286),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0xFF4B4239)),
          ),
        ),
      ],
    );
  }
}

class _BackPlate extends StatelessWidget {
  const _BackPlate();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF211B16),
        border: Border.all(color: const Color(0xFF342A22)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const SizedBox(width: 72, height: 72),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF020201)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const length = 36.0;
    const inset = 2.0;
    canvas.drawLine(const Offset(inset, 60), const Offset(inset, 20), paint);
    canvas.drawLine(const Offset(inset, 20), const Offset(42, 20), paint);
    canvas.drawLine(
      Offset(size.width - inset, 60),
      Offset(size.width - inset, 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, 20),
      Offset(size.width - 42, 20),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - 60),
      Offset(inset, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - 20),
      Offset(length + inset, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - 60),
      Offset(size.width - inset, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - 20),
      Offset(size.width - length - inset, size.height - 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
