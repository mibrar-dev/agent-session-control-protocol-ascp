import 'package:flutter/widgets.dart';

import '../application/inspect_controller.dart';
import '../data/inspect_repository.dart';
import '../domain/inspect_item.dart';

class InspectScreen extends StatelessWidget {
  InspectScreen({InspectController? controller, super.key})
    : controller =
          controller ??
          InspectController(repository: MemoryInspectRepository());

  final InspectController controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InspectState>(
      future: controller.load(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF100d08)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Body(
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.error,
                  state: state,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.isLoading,
    required this.error,
    required this.state,
  });

  final bool isLoading;
  final Object? error;
  final InspectState? state;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: _MutedCopy('Loading inspect metadata...'));
    }
    if (error != null) {
      return const Center(
        child: _MutedCopy('Unable to load inspect metadata.'),
      );
    }
    final current = state;
    if (current == null) {
      return const SizedBox.shrink();
    }
    if (!current.isSupported) {
      return Center(
        child: _MutedCopy(current.reason ?? 'Inspect is unavailable.'),
      );
    }
    if (current.items.isEmpty) {
      return const Center(child: _MutedCopy('No artifacts or diffs yet.'));
    }

    return _ArtifactViewer(items: current.items);
  }
}

class _ArtifactViewer extends StatelessWidget {
  const _ArtifactViewer({required this.items});

  final List<InspectItem> items;

  @override
  Widget build(BuildContext context) {
    final activeItem = items.first;
    final hasDiff = items.any((item) => item.kind == InspectItemKind.diff);
    return Column(
      children: [
        _ArtifactTopBar(item: activeItem),
        const _MetadataStrip(),
        _BadgeRow(hasDiff: hasDiff),
        _FilesTrigger(count: items.length),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 160, child: _FileTree(items: items)),
              const Expanded(child: _DiffViewer()),
            ],
          ),
        ),
        const _BottomActionBar(),
      ],
    );
  }
}

class _ArtifactTopBar extends StatelessWidget {
  const _ArtifactTopBar({required this.item});

  final InspectItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF100d08),
        border: Border(bottom: BorderSide(color: Color(0xFF2e2820))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
        child: Row(
          children: [
            const _IconButton(label: '‹'),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'middleware.ts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFf0e8dc),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _subtitleFor(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6a5a48),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _IconButton(label: '↥'),
            const SizedBox(width: 8),
            const _IconButton(label: '⋮'),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(InspectItem item) {
    if (item.id.startsWith('codex:')) {
      return item.id;
    }
    return 'src/auth/middleware.ts';
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1e1a14),
        border: Border.all(color: const Color(0xFF2e2820), width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8a7860),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataStrip extends StatelessWidget {
  const _MetadataStrip();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF140f09),
        border: Border(bottom: BorderSide(color: Color(0xFF2e2820))),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _MetaItem(label: 'File size', value: '8.4 KB'),
            ),
            _MetaDivider(),
            Expanded(
              child: _MetaItem.rich(
                label: 'Changed',
                children: [
                  TextSpan(
                    text: '+18',
                    style: TextStyle(color: Color(0xFF4a8a5e)),
                  ),
                  TextSpan(
                    text: '  −6',
                    style: TextStyle(color: Color(0xFF8a4040)),
                  ),
                ],
              ),
            ),
            _MetaDivider(),
            Expanded(
              child: _MetaItem(label: 'Session', value: 'refactor-auth'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value}) : children = null;

  const _MetaItem.rich({required this.label, required this.children})
    : value = null;

  final String label;
  final String? value;
  final List<TextSpan>? children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF4a3e30),
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        if (children == null)
          Text(
            value ?? '',
            style: const TextStyle(
              color: Color(0xFFc8b89a),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text.rich(
            TextSpan(children: children),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF2e2820)),
      child: SizedBox(width: 1, height: 26),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.hasDiff});

  final bool hasDiff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          const _Pill(
            label: 'Pending approval',
            color: Color(0xFFd4900c),
            background: Color(0xFF2a2010),
            border: Color(0xFF6a5020),
            dot: true,
          ),
          const SizedBox(width: 8),
          _Pill(
            label: hasDiff ? 'Medium risk' : 'Artifact review',
            color: const Color(0xFFc06030),
            background: const Color(0xFF2a1a10),
            border: const Color(0xFF6a3010),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
    required this.border,
    this.dot = false,
  });

  final String label;
  final Color color;
  final Color background;
  final Color border;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox(width: 5, height: 5),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesTrigger extends StatelessWidget {
  const _FilesTrigger({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1510),
        border: Border(bottom: BorderSide(color: Color(0xFF2e2820))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            const Text('▣', style: TextStyle(color: Color(0xFF6a5a48))),
            const SizedBox(width: 8),
            const Text(
              'Files',
              style: TextStyle(
                color: Color(0xFF8a7860),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$count ${count == 1 ? 'file' : 'files'}',
              style: const TextStyle(
                color: Color(0xFFc8b89a),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Text('›', style: TextStyle(color: Color(0xFF8a7860))),
          ],
        ),
      ),
    );
  }
}

class _FileTree extends StatelessWidget {
  const _FileTree({required this.items});

  final List<InspectItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(8).toList();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF140f09),
        border: Border(right: BorderSide(color: Color(0xFF2e2820))),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        children: [
          const _TreeDir(label: '⌄ src'),
          const _TreeDir(label: '  ⌄ auth'),
          const _TreeFile(label: '    middleware.ts', active: true),
          const _TreeFile(label: '    session.ts'),
          const _TreeFile(label: '  package.json'),
          const SizedBox(height: 6),
          ...visibleItems.map(
            (item) => _TreeFile(
              label: _treeLabel(item),
              active: false,
              semanticLabel: item.id,
            ),
          ),
        ],
      ),
    );
  }

  String _treeLabel(InspectItem item) {
    return item.id.length > 18 ? '${item.id.substring(0, 18)}…' : item.id;
  }
}

class _TreeDir extends StatelessWidget {
  const _TreeDir({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF4a3e30),
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _TreeFile extends StatelessWidget {
  const _TreeFile({
    required this.label,
    this.active = false,
    this.semanticLabel,
  });

  final String label;
  final bool active;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: active ? const Color(0xFFd4900c) : const Color(0xFF8a7860),
        fontSize: 12,
        fontFamily: 'monospace',
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2a2010) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: text,
      ),
    );
    if (semanticLabel == null) {
      return child;
    }
    return Semantics(label: semanticLabel, child: child);
  }
}

class _DiffViewer extends StatelessWidget {
  const _DiffViewer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 430,
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            _DiffLine(
              number: 94,
              marker: '',
              code: 'if (!session.token) return unauthorized();',
            ),
            _DiffLine(
              number: 95,
              marker: '',
              code: 'const user = await getUser(session.userId);',
            ),
            _DiffLine(number: 96, marker: '', code: ''),
            _DiffLine(
              number: 97,
              marker: '−',
              code: 'const allowGuest = true;',
              type: _DiffLineType.removed,
            ),
            _DiffLine(
              number: 97,
              marker: '+',
              code: 'const allowGuest = false;',
              type: _DiffLineType.added,
            ),
            _DiffLine(
              number: 98,
              marker: '+',
              code: 'enforceSessionGuard(request);',
              type: _DiffLineType.added,
            ),
            _DiffLine(
              number: 99,
              marker: '+',
              code: "logAuthEvent(user.id, 'session_guard');",
              type: _DiffLineType.added,
            ),
            _DiffLine(
              number: 100,
              marker: '+',
              code: 'await refreshTokenIfExpiring(session);',
              type: _DiffLineType.added,
            ),
            _DiffLine(number: 101, marker: '', code: ''),
            _DiffLine(number: 102, marker: '', code: 'return next();'),
            _DiffLine(number: 103, marker: '', code: '}'),
          ],
        ),
      ),
    );
  }
}

enum _DiffLineType { context, added, removed }

class _DiffLine extends StatelessWidget {
  const _DiffLine({
    required this.number,
    required this.marker,
    required this.code,
    this.type = _DiffLineType.context,
  });

  final int number;
  final String marker;
  final String code;
  final _DiffLineType type;

  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      _DiffLineType.added => const _DiffColors(
        background: Color(0xFF0d1e10),
        edge: Color(0xFF2d6a3a),
        lineBackground: Color(0xFF0d1a10),
        line: Color(0xFF3a7a48),
        marker: Color(0xFF4a9a5a),
        code: Color(0xFF80c890),
      ),
      _DiffLineType.removed => const _DiffColors(
        background: Color(0xFF1e0d0d),
        edge: Color(0xFF8a3030),
        lineBackground: Color(0xFF1a0d0d),
        line: Color(0xFF8a4040),
        marker: Color(0xFFc04040),
        code: Color(0xFFd08080),
      ),
      _DiffLineType.context => const _DiffColors(
        background: Color(0xFF100d08),
        edge: Color(0x00000000),
        lineBackground: Color(0xFF140f09),
        line: Color(0xFF3a3028),
        marker: Color(0xFF3a3028),
        code: Color(0xFF6a5a48),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.edge, width: 2)),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF140f09),
              border: Border(
                right: BorderSide(color: Color(0xFF2e2820), width: 0.5),
              ),
            ),
            child: SizedBox(
              width: 36,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$number',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.line,
                    fontSize: 10,
                    height: 1.75,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Text(
              marker,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.marker,
                fontSize: 12,
                height: 1.75,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: colors.code,
                fontSize: 12,
                height: 1.75,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffColors {
  const _DiffColors({
    required this.background,
    required this.edge,
    required this.lineBackground,
    required this.line,
    required this.marker,
    required this.code,
  });

  final Color background;
  final Color edge;
  final Color lineBackground;
  final Color line;
  final Color marker;
  final Color code;
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF140f09),
        border: Border(top: BorderSide(color: Color(0xFF2e2820))),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Row(
          children: [
            Expanded(child: _ActionButton(label: 'Copy')),
            SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _ActionButton(label: 'Open in session', amber: true),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _ActionButton(label: 'Approve patch', primary: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.primary = false,
    this.amber = false,
  });

  final String label;
  final bool primary;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary ? const Color(0xFFd4900c) : const Color(0xFF1e1a14),
        border: primary
            ? null
            : Border.all(color: const Color(0xFF2e2820), width: 0.5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: SizedBox(
        height: 42,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primary
                  ? const Color(0xFF1a0e04)
                  : amber
                  ? const Color(0xFFc8b89a)
                  : const Color(0xFF8a7860),
              fontSize: 13,
              fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MutedCopy extends StatelessWidget {
  const _MutedCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8a7860),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
