import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/design_system/continuum_tokens.dart';
import '../application/session_detail_controller.dart';
import '../data/session_repository.dart';
import '../domain/timeline_event.dart';

class SessionDetailScreen extends StatefulWidget {
  SessionDetailScreen({
    required this.sessionId,
    SessionDetailController? controller,
    super.key,
  }) : controller =
           controller ??
           SessionDetailController(
             sessionId: sessionId,
             repository: MemorySessionRepository(),
           );

  final String sessionId;
  final SessionDetailController controller;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  late final Future<void> _load = widget.controller.load(
    onEvent: () {
      if (mounted) {
        setState(() {});
      }
    },
  );

  @override
  void dispose() {
    unawaited(widget.controller.dispose());
    _inputFocusNode.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: ContinuumColorTokens.bgSurface,
          ),
          child: Column(
            children: [
              _SessionHeader(sessionId: widget.sessionId),
              const _DateDivider(label: 'Today'),
              Expanded(
                child: _TimelineFeed(
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.error,
                  timeline: widget.controller.timeline,
                ),
              ),
              _InputBar(
                controller: _inputController,
                focusNode: _inputFocusNode,
                onSend: _sendInput,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendInput() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    await widget.controller.sendInput(text);
    _inputController.clear();
    if (mounted) {
      setState(() {});
    }
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live feed',
                style: TextStyle(
                  color: ContinuumColorTokens.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: SessionColors.amberBg,
                  border: Border.all(color: SessionColors.amberBorder),
                  borderRadius: BorderRadius.circular(
                    ContinuumRadiusTokens.pill,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      color: SessionColors.amberText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            sessionId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ContinuumColorTokens.mutedText,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: ContinuumColorTokens.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(color: ContinuumColorTokens.border),
              child: SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineFeed extends StatelessWidget {
  const _TimelineFeed({
    required this.isLoading,
    required this.error,
    required this.timeline,
  });

  final bool isLoading;
  final Object? error;
  final List<TimelineEvent> timeline;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _MutedCopy('Loading timeline...');
    }
    if (error != null) {
      return const _MutedCopy('Unable to load timeline.');
    }
    if (timeline.isEmpty) {
      return const _MutedCopy('No timeline events yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: timeline.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _EventRenderer(event: timeline[index]),
    );
  }
}

class _EventRenderer extends StatelessWidget {
  const _EventRenderer({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final kind = _classifyEvent(event.label);

    return switch (kind) {
      _EventKind.userMessage => _UserBubble(event: event),
      _EventKind.agentMessage => _AgentMessage(event: event),
      _EventKind.tool => _ToolCard(event: event),
      _EventKind.approval => _ApprovalCard(event: event),
      _EventKind.terminal => _TerminalBlock(event: event),
      _EventKind.generic => _GenericEvent(event: event),
    };
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SessionColors.userBubbleBg,
            border: Border.all(color: SessionColors.userBubbleBorder),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(
              _eventDetail(event.label),
              style: const TextStyle(
                color: Color(0xFF3A2510),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentMessage extends StatelessWidget {
  const _AgentMessage({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final detail = _eventDetail(event.label);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _eventTitle(event.label),
              style: const TextStyle(
                color: ContinuumColorTokens.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: ContinuumColorTokens.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final title = _eventTitle(event.label);
    final detail = _eventDetail(event.label);
    final blocked = _isToolBlocked(event.label);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ContinuumColorTokens.bgElevated,
            border: Border.all(
              color: blocked
                  ? ContinuumColorTokens.danger.withValues(alpha: 0.35)
                  : ContinuumColorTokens.border,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ToolGlyph(blocked: blocked),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ContinuumColorTokens.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _ToolStatusPill(blocked: blocked),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ContinuumColorTokens.mutedText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolGlyph extends StatelessWidget {
  const _ToolGlyph({required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: blocked ? SessionColors.toolRedBg : SessionColors.toolIndigoBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: Text(
            blocked ? '✕' : 'T',
            style: TextStyle(
              color: blocked
                  ? ContinuumColorTokens.danger
                  : SessionColors.toolIndigoIcon,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolStatusPill extends StatelessWidget {
  const _ToolStatusPill({required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final color = blocked
        ? ContinuumColorTokens.danger
        : ContinuumColorTokens.success;
    final label = blocked ? 'Blocked' : 'Done';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final detail = _eventDetail(event.label);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SessionColors.approvalBg,
            border: Border.all(color: SessionColors.amberBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ShieldGlyph(),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Approval requested',
                        style: TextStyle(
                          color: SessionColors.amberText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: SessionColors.codeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        detail,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SessionColors.codeText,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const _ApprovalActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SessionColors.shieldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: Text(
            '⛨',
            style: TextStyle(
              color: SessionColors.shieldStroke,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovalActions extends StatelessWidget {
  const _ApprovalActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Deny',
            background: SessionColors.denyBg,
            textColor: ContinuumColorTokens.danger,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _ActionButton(
            label: 'Approve',
            background: SessionColors.approveBg,
            textColor: ContinuumColorTokens.success,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TerminalBlock extends StatelessWidget {
  const _TerminalBlock({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final detail = _eventDetail(event.label);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B16),
            border: Border.all(color: ContinuumColorTokens.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ContinuumColorTokens.mono.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          '>',
                          style: TextStyle(
                            color: ContinuumColorTokens.mono,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Terminal',
                      style: TextStyle(
                        color: ContinuumColorTokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (event.sequence != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: ContinuumColorTokens.mono.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            ContinuumRadiusTokens.pill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            '#${event.sequence}',
                            style: const TextStyle(
                              color: ContinuumColorTokens.mono,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  detail.isEmpty ? event.label : detail,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ContinuumColorTokens.mono,
                    fontSize: 12,
                    height: 1.4,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenericEvent extends StatelessWidget {
  const _GenericEvent({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final title = _eventTitle(event.label);
    final detail = _eventDetail(event.label);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ContinuumColorTokens.bgElevated,
            border: Border.all(color: ContinuumColorTokens.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ContinuumColorTokens.accent.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          '*',
                          style: TextStyle(
                            color: ContinuumColorTokens.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ContinuumColorTokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (event.sequence != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: ContinuumColorTokens.accent.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            ContinuumRadiusTokens.pill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            '#${event.sequence}',
                            style: TextStyle(
                              color: ContinuumColorTokens.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ContinuumColorTokens.mutedText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ContinuumColorTokens.bgElevated,
          border: Border.all(
            color: focusNode.hasFocus
                ? ContinuumColorTokens.accent
                : ContinuumColorTokens.border,
          ),
          borderRadius: BorderRadius.circular(ContinuumRadiusTokens.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditableText(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: ContinuumColorTokens.textPrimary,
                  fontSize: 15,
                  height: 1.35,
                ),
                cursorColor: ContinuumColorTokens.accent,
                backgroundCursorColor: ContinuumColorTokens.border,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _AgentAvatar(),
                  const SizedBox(width: 6),
                  const Text(
                    'Quick',
                    style: TextStyle(
                      color: ContinuumColorTokens.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSend,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ContinuumColorTokens.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Send',
                          style: TextStyle(
                            color: ContinuumColorTokens.accentForeground,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContinuumColorTokens.bgOverlay,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Text(
            'A',
            style: TextStyle(
              color: ContinuumColorTokens.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

enum _EventKind { userMessage, agentMessage, tool, approval, terminal, generic }

_EventKind _classifyEvent(String label) {
  final normalized = label.toLowerCase();
  if (normalized.startsWith('message.user') || normalized.startsWith('user.')) {
    return _EventKind.userMessage;
  }
  if (normalized.startsWith('message.agent') ||
      normalized.startsWith('message.assistant') ||
      normalized.contains('thinking')) {
    return _EventKind.agentMessage;
  }
  if (normalized.contains('approval')) {
    return _EventKind.approval;
  }
  if (normalized.startsWith('terminal') ||
      normalized.contains('terminal.') ||
      normalized.contains('stdout') ||
      normalized.contains('stderr')) {
    return _EventKind.terminal;
  }
  if (normalized.startsWith('tool.') || normalized.contains('tool')) {
    return _EventKind.tool;
  }
  return _EventKind.generic;
}

String _eventTitle(String label) {
  if (label.startsWith('message.user')) return 'You';
  if (label.startsWith('message.agent') ||
      label.startsWith('message.assistant')) {
    return 'Agent';
  }
  if (label.toLowerCase().contains('approval')) return 'Approval requested';
  if (label.toLowerCase().startsWith('terminal')) return 'Terminal';
  if (label.toLowerCase().contains('tool')) return label.split(' ').first;
  final detail = _eventDetail(label);
  return detail.isEmpty ? label : label.split(' ').first;
}

String _eventDetail(String label) {
  final separator = label.indexOf(' ');
  if (separator == -1 || separator == label.length - 1) return '';
  return label.substring(separator + 1);
}

bool _isToolBlocked(String label) {
  final normalized = label.toLowerCase();
  return normalized.contains('blocked') || normalized.contains('failed');
}

class _MutedCopy extends StatelessWidget {
  const _MutedCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: ContinuumColorTokens.mutedText,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
