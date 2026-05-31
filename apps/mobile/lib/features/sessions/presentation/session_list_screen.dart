import 'package:flutter/widgets.dart';

import '../../../core/design_system/continuum_tokens.dart';
import '../application/session_list_controller.dart';
import '../data/session_repository.dart';
import '../domain/timeline_event.dart';

class SessionListScreen extends StatelessWidget {
  SessionListScreen({
    SessionListController? controller,
    this.onSessionSelected,
    super.key,
  }) : controller =
           controller ??
           SessionListController(repository: MemorySessionRepository());

  final SessionListController controller;
  final ValueChanged<SessionSummary>? onSessionSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionSummary>>(
      future: controller.load(),
      builder: (context, snapshot) {
        final sessions = snapshot.data;
        return DecoratedBox(
          decoration: const BoxDecoration(color: SessionColors.pageBackground),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: _SessionScreenFrame(
              title: 'Sessions',
              child: _SessionListBody(
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                sessions: sessions ?? const [],
                onSessionSelected: onSessionSelected,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionScreenFrame extends StatelessWidget {
  const _SessionScreenFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 14),
          child: Text(
            title,
            style: const TextStyle(
              color: SessionColors.textDark,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SessionListBody extends StatelessWidget {
  const _SessionListBody({
    required this.isLoading,
    required this.error,
    required this.sessions,
    required this.onSessionSelected,
  });

  final bool isLoading;
  final Object? error;
  final List<SessionSummary> sessions;
  final ValueChanged<SessionSummary>? onSessionSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _MutedCopy('Loading sessions...');
    }
    if (error != null) {
      return const _MutedCopy('Unable to load sessions.');
    }
    if (sessions.isEmpty) {
      return const _MutedCopy('No active sessions');
    }

    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _SessionItem(
        session: sessions[index],
        onTap: onSessionSelected == null
            ? null
            : () => onSessionSelected!(sessions[index]),
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  const _SessionItem({required this.session, this.onTap});

  final SessionSummary session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(session.status);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SessionColors.cardSurface,
          border: Border.all(color: SessionColors.borderCard),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _StatusIcon(status: session.status, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SessionColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SessionColors.textMuted,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(status: session.status, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            _iconGlyph(status),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDot(color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox(width: 6, height: 6),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'running' => ContinuumColorTokens.success,
    'waiting_approval' => ContinuumColorTokens.warning,
    'waiting_input' => ContinuumColorTokens.warning,
    'idle' => ContinuumColorTokens.accent,
    'completed' => ContinuumColorTokens.mutedText,
    'failed' => ContinuumColorTokens.danger,
    'stopped' => ContinuumColorTokens.danger,
    'disconnected' => ContinuumColorTokens.danger,
    _ => ContinuumColorTokens.mutedText,
  };
}

String _iconGlyph(String status) {
  return switch (status) {
    'running' => '▶',
    'waiting_approval' => '!',
    'waiting_input' => '?',
    'idle' => '◉',
    'completed' => '✓',
    'failed' => '✕',
    'stopped' => '■',
    'disconnected' => '—',
    _ => '•',
  };
}

class _MutedCopy extends StatelessWidget {
  const _MutedCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: SessionColors.textMuted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
