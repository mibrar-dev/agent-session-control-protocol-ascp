import 'package:flutter/widgets.dart';

import '../../../core/design_system/continuum_tokens.dart';
import '../application/approval_queue_controller.dart';
import '../data/approval_repository.dart';
import '../domain/approval_view_model.dart';

class ApprovalsScreen extends StatelessWidget {
  ApprovalsScreen({ApprovalQueueController? controller, super.key})
    : controller =
          controller ??
          ApprovalQueueController(repository: MemoryApprovalRepository());

  final ApprovalQueueController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SessionColors.pageBackground),
      child: FutureBuilder<List<ApprovalViewModel>>(
        future: controller.loadQueue(),
        builder: (context, snapshot) {
          final approvals = snapshot.data ?? const <ApprovalViewModel>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(approvalsCount: approvals.length),
              Expanded(
                child: _ApprovalBody(
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.error,
                  approvals: approvals,
                  controller: controller,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.approvalsCount});

  final int approvalsCount;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (approvalsCount) {
      0 => 'No pending actions',
      1 => '1 pending action',
      _ => '$approvalsCount pending actions',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Approvals',
                style: TextStyle(
                  color: SessionColors.textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: SessionColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: SessionColors.cardSurface,
              border: Border.all(color: SessionColors.borderLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  '⚙',
                  style: TextStyle(color: SessionColors.textDark, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalBody extends StatefulWidget {
  const _ApprovalBody({
    required this.isLoading,
    required this.error,
    required this.approvals,
    required this.controller,
  });

  final bool isLoading;
  final Object? error;
  final List<ApprovalViewModel> approvals;
  final ApprovalQueueController controller;

  @override
  State<_ApprovalBody> createState() => _ApprovalBodyState();
}

class _ApprovalBodyState extends State<_ApprovalBody> {
  late List<ApprovalViewModel> _approvals = widget.approvals;

  @override
  void didUpdateWidget(covariant _ApprovalBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.approvals != widget.approvals) {
      _approvals = widget.approvals;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: _MutedCopy('Loading approvals...'));
    }
    if (widget.error != null) {
      return const Center(child: _MutedCopy('Unable to load approvals.'));
    }
    if (_approvals.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: _approvals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _ApprovalCard(
        approval: _approvals[index],
        onDecision: (decision) => _respond(index, decision),
      ),
    );
  }

  Future<void> _respond(int index, ApprovalDecision decision) async {
    final updated = await widget.controller.respond(
      approval: _approvals[index],
      decision: decision,
    );
    if (!mounted) return;
    setState(() {
      _approvals = [
        for (final entry in _approvals.indexed)
          if (entry.$1 == index) updated else entry.$2,
      ];
    });
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.approval, required this.onDecision});

  final ApprovalViewModel approval;
  final ValueChanged<ApprovalDecision> onDecision;

  @override
  Widget build(BuildContext context) {
    final isHighRisk =
        approval.reason.contains('high') || approval.reason.contains('system');
    final accentColor = isHighRisk
        ? ContinuumColorTokens.warning
        : SessionColors.amberText;
    final accentBg = isHighRisk
        ? ContinuumColorTokens.warning.withValues(alpha: 0.12)
        : SessionColors.amberBg;
    final riskLabel = isHighRisk ? 'High risk' : 'Medium risk';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SessionColors.cardSurface,
        border: Border.all(color: SessionColors.borderCard),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 3,
            width: double.infinity,
            child: ColoredBox(color: accentColor),
          ),
          _Header(
            agentName: approval.sessionId,
            sessionName: 'refactor-auth',
            risk: riskLabel,
            accentBg: accentBg,
            accentText: accentColor,
          ),
          const _CardDivider(),
          _Body(
            actionLabel: approval.reason,
            description: 'Agent requested permission to perform this action.',
            path: '/etc/hosts',
            accentBg: accentBg,
          ),
          if (isHighRisk) ...[const _CardDivider(), const _WarningBlock()],
          const _CardDivider(),
          _ActionRow(
            onApprove: () => onDecision(ApprovalDecision.approved),
            onReject: () => onDecision(ApprovalDecision.rejected),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SessionColors.borderLight, width: 0.5),
        ),
      ),
      child: SizedBox(height: 1, width: double.infinity),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.agentName,
    required this.sessionName,
    required this.risk,
    required this.accentBg,
    required this.accentText,
  });

  final String agentName;
  final String sessionName;
  final String risk;
  final Color accentBg;
  final Color accentText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  '⬡',
                  style: TextStyle(
                    color: SessionColors.amberText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentName,
                  style: const TextStyle(
                    color: SessionColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sessionName,
                  style: const TextStyle(
                    color: SessionColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: accentBg,
              border: Border.all(color: accentText.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                risk,
                style: TextStyle(
                  color: accentText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.actionLabel,
    required this.description,
    required this.path,
    required this.accentBg,
  });

  final String actionLabel;
  final String description;
  final String path;
  final Color accentBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: Text(
                      '›',
                      style: TextStyle(
                        color: SessionColors.amberText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: SessionColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: SessionColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: SessionColors.warmSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  const Text(
                    '⌸ ',
                    style: TextStyle(
                      color: SessionColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    path,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: SessionColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBlock extends StatelessWidget {
  const _WarningBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      child: Row(
        children: [
          const Text(
            '⚠ ',
            style: TextStyle(color: ContinuumColorTokens.warning, fontSize: 13),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'System file modification. This action cannot be undone automatically. Verify agent intent before approving.',
              style: const TextStyle(
                color: ContinuumColorTokens.warning,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onApprove, required this.onReject});

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onReject,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SessionColors.denyBg,
                  border: Border.all(
                    color: ContinuumColorTokens.danger.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const SizedBox(
                  height: 42,
                  child: Center(
                    child: Text(
                      'Reject',
                      style: TextStyle(
                        color: ContinuumColorTokens.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onApprove,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SessionColors.approveBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const SizedBox(
                  height: 42,
                  child: Center(
                    child: Text(
                      'Approve',
                      style: TextStyle(
                        color: ContinuumColorTokens.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: SessionColors.warmSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const SizedBox(
                width: 88,
                height: 88,
                child: Center(
                  child: Text(
                    '⛨',
                    style: TextStyle(
                      color: SessionColors.amberText,
                      fontSize: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No pending approvals',
              style: TextStyle(
                color: SessionColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agent actions that need your review will appear here. Your agents are running smoothly.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SessionColors.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const Text(
                'View completed approvals',
                style: TextStyle(
                  color: SessionColors.textMuted,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: SessionColors.textMuted,
                ),
              ),
            ),
          ],
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
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: SessionColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
