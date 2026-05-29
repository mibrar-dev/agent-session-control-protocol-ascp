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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pair a host',
            style: TextStyle(
              color: ContinuumColorTokens.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_claiming) ...[
            const Text('Claiming...', style: _bodyStyle),
          ] else if (state.isTrusted) ...[
            const Text('Trusted device', style: _titleStyle),
            const SizedBox(height: 12),
            _ActionText(label: 'Continue', onTap: widget.onContinue ?? () {}),
          ] else if (state.isFailed) ...[
            Text(_failureLabel(state.failure), style: _titleStyle),
            const SizedBox(height: 12),
            _ActionText(
              label: 'Try again',
              onTap: () => setState(widget.controller.cancel),
            ),
          ] else if (state.isScanning) ...[
            const Text('Scanning...', style: _bodyStyle),
            const SizedBox(height: 12),
            _ActionText(
              label: 'Cancel',
              onTap: () => setState(widget.controller.cancel),
            ),
          ] else if (state.isPolling) ...[
            const Text('Waiting for host approval', style: _titleStyle),
            const SizedBox(height: 8),
            const Text(
              'Approve this device on the host to finish pairing.',
              style: _bodyStyle,
            ),
            const SizedBox(height: 12),
            _ActionText(
              label: 'Cancel',
              onTap: () => setState(widget.controller.cancel),
            ),
          ] else if (state.isManualInput) ...[
            _ManualInput(controller: _textController, focusNode: _focusNode),
            const SizedBox(height: 12),
            _ActionText(label: 'Submit', onTap: _submitManual),
          ] else ...[
            _ActionText(label: 'Scan QR code', onTap: _scan),
            const SizedBox(height: 12),
            _ActionText(
              label: 'Enter code manually',
              onTap: () => setState(widget.controller.startManualInput),
            ),
          ],
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
    setState(() => _claiming = true);
    await widget.controller.submitPayload(payload);
    if (mounted) {
      setState(() => _claiming = false);
    }
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

class _ManualInput extends StatelessWidget {
  const _ManualInput({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: ContinuumColorTokens.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: _bodyStyle,
          cursorColor: ContinuumColorTokens.accent,
          backgroundCursorColor: ContinuumColorTokens.border,
        ),
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(label, style: _bodyStyle),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: ContinuumColorTokens.textPrimary,
  fontSize: 18,
  fontWeight: FontWeight.w700,
);

const _bodyStyle = TextStyle(
  color: ContinuumColorTokens.textPrimary,
  fontSize: 14,
  height: 1.45,
);
