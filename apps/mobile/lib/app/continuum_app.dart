import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/continuum_theme.dart';
import '../core/design_system/continuum_tokens.dart';
import '../features/approvals/domain/approval_view_model.dart';
import '../features/approvals/presentation/approvals_screen.dart';
import '../features/settings/presentation/devices_screen.dart';
import '../features/pairing/presentation/pairing_screen.dart';
import '../features/sessions/application/session_detail_controller.dart';
import '../features/sessions/domain/timeline_event.dart';
import '../features/sessions/presentation/session_detail_screen.dart';
import '../features/sessions/presentation/session_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../ui/shadcn/components/display/badge/badge.dart' as shadcn;
import '../ui/shadcn/shared/theme/theme.dart' as shadcn;
import 'mobile_dependencies.dart';
import 'mobile_providers.dart';

class ContinuumMobileApp extends ConsumerStatefulWidget {
  const ContinuumMobileApp({
    super.key,
    this.isTrusted = false,
    this.dependencies,
  });

  final bool isTrusted;
  final MobileDependencies? dependencies;

  @override
  ConsumerState<ContinuumMobileApp> createState() => _ContinuumMobileAppState();
}

class _ContinuumMobileAppState extends ConsumerState<ContinuumMobileApp> {
  late bool _isTrusted;

  @override
  void initState() {
    super.initState();
    _isTrusted = widget.isTrusted;
    if (!_isTrusted) {
      _restoreStoredTrust();
    }
  }

  @override
  Widget build(BuildContext context) {
    final explicitDependencies = widget.dependencies;
    final resolvedDependencies = explicitDependencies ?? _readDependencies(ref);

    return WidgetsApp(
      title: 'Continuum',
      color: ContinuumColorTokens.accent,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(settings, builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
        );
      },
      home: shadcn.Theme(
        data: buildContinuumTheme(),
        child: _isTrusted
            ? ContinuumTrustedShell(dependencies: resolvedDependencies)
            : ContinuumFirstRunShell(
                dependencies: resolvedDependencies,
                onTrusted: () => setState(() => _isTrusted = true),
              ),
      ),
    );
  }

  Future<void> _restoreStoredTrust() async {
    final dependencies =
        widget.dependencies ?? _readDependencies(ref, listen: false);
    final material = await dependencies.pairingController.secureStore
        .readTrustMaterial();
    if (!mounted || material == null) {
      return;
    }
    setState(() => _isTrusted = true);
  }

  MobileDependencies _readDependencies(WidgetRef ref, {bool listen = true}) {
    try {
      return listen
          ? ref.watch(mobileDependenciesProvider)
          : ref.read(mobileDependenciesProvider);
    } on StateError {
      return MobileDependencies.memory();
    }
  }
}

class ContinuumTrustedShell extends StatefulWidget {
  const ContinuumTrustedShell({super.key, this.dependencies});

  final MobileDependencies? dependencies;

  @override
  State<ContinuumTrustedShell> createState() => _ContinuumTrustedShellState();
}

class _ContinuumTrustedShellState extends State<ContinuumTrustedShell> {
  int _index = 0;
  SessionSummary? _selectedSession;
  late final MobileDependencies _dependencies;
  late List<_ShellTab> _tabs;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ?? MobileDependencies.memory();
    _tabs = _buildTabs();
    _loadBadgeCounts();
  }

  List<_ShellTab> _buildTabs({int runningCount = 0, int pendingCount = 0}) => [
    const _ShellTab('Home', '⌂'),
    _ShellTab('Sessions', '☷', badgeCount: runningCount),
    _ShellTab('Approvals', '✓', badgeCount: pendingCount),
    _ShellTab('Devices', '▰', badgeCount: pendingCount),
    const _ShellTab('Settings', '⚙'),
  ];

  Future<void> _loadBadgeCounts() async {
    try {
      final sessions = await _dependencies.sessionListController.load();
      final approvals = await _dependencies.approvalQueueController.loadQueue();
      final runningCount = sessions.where((s) => s.status == 'running').length;
      final pendingCount = approvals
          .where((a) => a.status == ApprovalStatus.pending)
          .length;
      if (mounted) {
        setState(() {
          _tabs = _buildTabs(
            runningCount: runningCount,
            pendingCount: pendingCount,
          );
        });
      }
    } catch (_) {
      // Dashboard badges should not block the shell.
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _tabs[_index];
    return ColoredBox(
      color: SessionColors.pageBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _TrustedTabView(
                tab: active,
                dependencies: _dependencies,
                selectedSession: _selectedSession,
                onNavigate: _selectTab,
                onSessionSelected: (session) =>
                    setState(() => _selectedSession = session),
                onSessionBack: () => setState(() => _selectedSession = null),
              ),
            ),
            _BottomNav(index: _index, tabs: _tabs, onSelected: _selectTab),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _index = index;
      if (_tabs[index].label != 'Sessions') {
        _selectedSession = null;
      }
    });
  }
}

class _TrustedTabView extends StatelessWidget {
  const _TrustedTabView({
    required this.tab,
    required this.dependencies,
    required this.selectedSession,
    required this.onNavigate,
    required this.onSessionSelected,
    required this.onSessionBack,
  });

  final _ShellTab tab;
  final MobileDependencies dependencies;
  final SessionSummary? selectedSession;
  final ValueChanged<int> onNavigate;
  final ValueChanged<SessionSummary> onSessionSelected;
  final VoidCallback onSessionBack;

  @override
  Widget build(BuildContext context) {
    return switch (tab.label) {
      'Sessions' =>
        selectedSession == null
            ? SessionListScreen(
                controller: dependencies.sessionListController,
                onSessionSelected: onSessionSelected,
              )
            : Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSessionBack,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(8, 4, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: SessionColors.amberText,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SessionDetailScreen(
                      sessionId: selectedSession!.id,
                      controller: SessionDetailController(
                        sessionId: selectedSession!.id,
                        repository:
                            dependencies.sessionListController.repository,
                        subscriptionRepository: dependencies
                            .createSessionSubscriptionRepository(),
                      ),
                    ),
                  ),
                ],
              ),

      'Approvals' => ApprovalsScreen(
        controller: dependencies.approvalQueueController,
      ),
      'Devices' => DevicesScreen(controller: dependencies.settingsController),
      'Settings' => SettingsScreen(controller: dependencies.settingsController),
      _ => _HomeDashboard(dependencies: dependencies, onNavigate: onNavigate),
    };
  }
}

class _DashboardData {
  const _DashboardData({
    required this.sessions,
    required this.runningCount,
    required this.pendingCount,
  });

  final List<SessionSummary> sessions;
  final int runningCount;
  final int pendingCount;
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard({required this.dependencies, required this.onNavigate});

  final MobileDependencies dependencies;
  final ValueChanged<int> onNavigate;

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  late final Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final sessions = data?.sessions.isNotEmpty == true
            ? data!.sessions
            : _fallbackSessions;

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          children: [
            const _HomeHeader(),
            const SizedBox(height: 22),
            _HostCard(diagnosticsText: 'Connected via local relay'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PrimaryAction(
                    label: 'New session',
                    glyph: '+',
                    onTap: () => widget.onNavigate(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryAction(
                    label: 'Approvals',
                    glyph: '✓',
                    badgeCount: data?.pendingCount ?? 2,
                    onTap: () => widget.onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Recent sessions'),
            const SizedBox(height: 12),
            for (final session in sessions.take(4)) ...[
              _RecentSessionCard(session: session),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            const _SectionLabel('System health'),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _HealthCard(label: 'CPU', value: '34%'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _HealthCard(label: 'Memory', value: '6.8 GB'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _HealthCard(label: 'Active\nagents', value: '3'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<_DashboardData> _loadData() async {
    final sessions = await widget.dependencies.sessionListController.load();
    final approvals = await widget.dependencies.approvalQueueController
        .loadQueue();
    return _DashboardData(
      sessions: sessions,
      runningCount: sessions.where((s) => s.status == 'running').length,
      pendingCount: approvals
          .where((a) => a.status == ApprovalStatus.pending)
          .length,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good evening, Muhammad',
                style: TextStyle(
                  color: SessionColors.textMuted,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Semantics(
                identifier: 'continuum_header',
                child: Text(
                  'Sessio',
                  style: TextStyle(
                    color: SessionColors.textDark,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        _IconButtonShell(glyph: '☼'),
      ],
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.diagnosticsText});

  final String diagnosticsText;

  @override
  Widget build(BuildContext context) {
    return _LightCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const _SquareIcon(glyph: '▱', bg: Color(0xFFE8E1D6)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MacBook Pro · Local',
                      style: TextStyle(
                        color: SessionColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      diagnosticsText,
                      style: const TextStyle(
                        color: SessionColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const _TrustPill(),
            ],
          ),
          const SizedBox(height: 16),
          const _Hairline(),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Last heartbeat 4s  ago',
                  style: TextStyle(
                    color: SessionColors.textMuted,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '18 ms',
                style: TextStyle(
                  color: SessionColors.textSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '✓',
                style: TextStyle(
                  color: ContinuumColorTokens.success,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFBD7A52),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBD7A52).withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                glyph,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 28),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.glyph,
    required this.badgeCount,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _LightCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 72,
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(glyph, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: SessionColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 12,
                  right: 18,
                  child: _BadgeBubble(count: badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(session.status);
    return _LightCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareIcon(
            glyph: _statusGlyph(session.status),
            bg: color.withValues(alpha: 0.10),
            fg: color,
          ),
          const SizedBox(width: 14),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sessionSubtitle(session),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SessionColors.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 9),
                _SoftStatusPill(
                  label: _statusLabel(session.status),
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeAge(session.updatedAt),
            style: const TextStyle(
              color: SessionColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _LightCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SessionColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SessionColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicatorStub(),
          ),
        ],
      ),
    );
  }
}

class LinearProgressIndicatorStub extends StatelessWidget {
  const LinearProgressIndicatorStub({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Row(
        children: const [
          Expanded(flex: 34, child: ColoredBox(color: Color(0xFFBD7A52))),
          Expanded(flex: 66, child: ColoredBox(color: Color(0xFFE8E1D8))),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.tabs,
    required this.onSelected,
  });

  final int index;
  final List<_ShellTab> tabs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF8),
        border: Border(top: BorderSide(color: SessionColors.borderLight)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            for (final entry in tabs.indexed)
              Expanded(
                child: _NavButton(
                  tab: entry.$2,
                  selected: entry.$1 == index,
                  onTap: () => onSelected(entry.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? SessionColors.textDark : const Color(0xFFB9B0A4);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        identifier: 'nav_${tab.label.toLowerCase()}',
        child: SizedBox(
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tab.glyph,
                    style: TextStyle(
                      color: color,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (tab.badgeCount > 0)
                Positioned(
                  top: 3,
                  right: 17,
                  child: _BadgeBubble(count: tab.badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.glyph, {this.badgeCount = 0});

  final String label;
  final String glyph;
  final int badgeCount;
}

class ContinuumFirstRunShell extends StatefulWidget {
  const ContinuumFirstRunShell({super.key, this.dependencies, this.onTrusted});

  final MobileDependencies? dependencies;
  final VoidCallback? onTrusted;

  @override
  State<ContinuumFirstRunShell> createState() => _ContinuumFirstRunShellState();
}

class _ContinuumFirstRunShellState extends State<ContinuumFirstRunShell> {
  late final MobileDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ?? MobileDependencies.memory();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF100D08),
      child: SafeArea(
        child: PairingScreen(
          controller: _dependencies.pairingController,
          scanner: _dependencies.pairingScanner,
          onContinue: widget.onTrusted,
        ),
      ),
    );
  }
}

class _LightCard extends StatelessWidget {
  const _LightCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SessionColors.cardSurface,
        border: Border.all(color: SessionColors.borderCard),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2A18).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _IconButtonShell extends StatelessWidget {
  const _IconButtonShell({required this.glyph});

  final String glyph;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFECE6DD),
        border: Border.all(color: SessionColors.borderLight),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Center(
          child: Text(
            glyph,
            style: const TextStyle(
              color: SessionColors.textSecondary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({
    required this.glyph,
    required this.bg,
    this.fg = SessionColors.textSecondary,
  });

  final String glyph;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Center(
          child: Text(
            glyph,
            style: TextStyle(
              color: fg,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill();

  @override
  Widget build(BuildContext context) {
    return shadcn.SecondaryBadge(
      child: const Text('● Trusted', style: TextStyle(fontSize: 14)),
    );
  }
}

class _SoftStatusPill extends StatelessWidget {
  const _SoftStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          child: Text(
            '● $label',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeBubble extends StatelessWidget {
  const _BadgeBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFC84F4F),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 23,
        height: 23,
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: SessionColors.textMuted,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: SessionColors.borderLight),
    );
  }
}

final _fallbackSessions = [
  SessionSummary(
    id: 'code-review',
    title: 'code-review',
    status: 'running',
    updatedAt: DateTime(2026, 5, 31, 9, 29),
  ),
  SessionSummary(
    id: 'refactor-auth',
    title: 'refactor-auth',
    status: 'waiting_approval',
    updatedAt: DateTime(2026, 5, 31, 9, 13),
  ),
  SessionSummary(
    id: 'fix-streaming-sse',
    title: 'fix-streaming-sse',
    status: 'stopped',
    updatedAt: DateTime(2026, 5, 31, 8, 37),
  ),
  SessionSummary(
    id: 'ship-mobile-ui',
    title: 'ship-mobile-ui',
    status: 'completed',
    updatedAt: DateTime(2026, 5, 30, 15, 10),
  ),
];

Color _statusColor(String status) {
  return switch (status) {
    'running' => const Color(0xFF3F8F60),
    'waiting_approval' || 'waiting_input' => const Color(0xFFA46D22),
    'completed' => const Color(0xFF8B867C),
    'stopped' => const Color(0xFF6C665D),
    _ => ContinuumColorTokens.danger,
  };
}

String _statusGlyph(String status) {
  return switch (status) {
    'running' => '▷',
    'waiting_approval' => '◷',
    'completed' => '✓',
    'stopped' => 'Ⅱ',
    _ => '!',
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'running' => 'Running',
    'waiting_approval' => 'Waiting approval',
    'completed' => 'Completed',
    'stopped' => 'Paused',
    _ => status.replaceAll('_', ' '),
  };
}

String _sessionSubtitle(SessionSummary session) {
  return switch (session.status) {
    'running' => 'Reviewing PR diff for auth/session.ts...',
    'waiting_approval' => 'Needs permission to modify middleware.ts',
    'stopped' => 'Paused after transport reconnect test',
    'completed' => 'Generated final Flutter layout notes',
    _ => session.id,
  };
}

String _relativeAge(DateTime updatedAt) {
  final diff = DateTime(2026, 5, 31, 9, 41).difference(updatedAt);
  if (diff.inDays >= 1) {
    return 'Yesterday';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }
  return '${diff.inHours}h ${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
}
