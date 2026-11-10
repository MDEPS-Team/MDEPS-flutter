import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/ui_message_listener.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/gro/application/gro_controllers.dart';

/// Governance & resource optimization hub (portfolio-wide).
class GovernanceHubScreen extends StatelessWidget {
  const GovernanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hub = AppScope.of(context).governanceHub;
    final nav = ShellScope.of(context);
    final p = context.vx;

    return UiMessageListener(
      messages: hub.messages,
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: VxTopBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Caption(context.tr('gro_governance_tab_title'), color: Vx.blue),
              Text(
                context.tr('gro_governance_opt_title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: p.ink),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Pill(context.tr('gro_governance_active'), bg: p.greenSoft, fg: Vx.green)),
            ),
            ProfileButton(tooltip: context.tr('nav_tab_profile'), onTap: () => nav.goTab(AppTab.profile)),
          ],
        ),
        body: ListenableBuilder(
          listenable: hub,
          builder: (context, _) {
            final s = hub.state;
            final children = <Widget>[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('gro_governance_opt_title'),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.ink),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: hub.auditInProgress ? null : hub.runFullAudit,
                    icon: hub.auditInProgress
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.fact_check, size: 16),
                    label: Text(context.tr('gro_run_full_audit')),
                  ),
                ],
              ),
              _ComplianceHero(percent: s.compliancePercent, delta: s.complianceDelta, violations: s.criticalViolations),
              _FrameworkCards(soc2On: s.policies.soc2Enabled, violations: s.criticalViolations),
              _ProtocolCard(lastAuditDays: s.lastAuditDaysAgo, daemonChecks: s.criticalViolations.clamp(0, 4)),
              Caption(context.tr('gro_bandwidth_title')),
              for (final row in s.bandwidthRows) _BandwidthRow(row: row),
              if (s.showOptimizationCard)
                _OptimizationCard(target: s.optimizationTargetProject, onApply: hub.applyOptimization),
              _BudgetRow(capUsd: s.budgetCapUsd, burn: s.burnRatePercent, index: s.deliveryIndex),
              Row(
                children: [
                  Expanded(child: Caption(context.tr('gro_protocols_title'))),
                  Text(
                    context.tr('gro_all_policies'),
                    style: const TextStyle(color: Vx.blue, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              _PolicyToggle(
                title: context.tr('gro_policy_soc2_title'),
                description: context.tr('gro_policy_soc2_desc'),
                value: s.policies.soc2Enabled,
                onChanged: hub.setSoc2,
              ),
              _PolicyToggle(
                title: context.tr('gro_policy_gates_title'),
                description: context.tr('gro_policy_gates_desc'),
                value: s.policies.gateReviewsEnabled,
                onChanged: hub.setGateReviews,
              ),
              _PolicyToggle(
                title: context.tr('gro_policy_budget_title'),
                description: context.tr('gro_policy_budget_desc'),
                value: s.policies.budgetGuardrailsEnabled,
                onChanged: hub.setBudgetGuardrails,
              ),
              if (s.escalations.isEmpty)
                VxCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.tr('gro_governance_no_escalations'), style: TextStyle(color: p.muted)),
                )
              else ...[
                Caption(context.tr('gro_governance_interventions_title')),
                for (final e in s.escalations)
                  _EscalationCard(
                    key: ValueKey(e.projectId),
                    item: e,
                    onRisks: () => nav.openProjectRisks(e.projectId),
                    onTimeline: () => nav.openProjectMilestones(e.projectId),
                  ),
              ],
            ];
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => children[i],
            );
          },
        ),
      ),
    );
  }
}

class _ComplianceHero extends StatelessWidget {
  const _ComplianceHero({required this.percent, required this.delta, required this.violations});

  final int percent;
  final double delta;
  final int violations;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(context.tr('gro_compliance_title')),
                Text(
                  '$percent%',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 36, color: Vx.blue),
                ),
                if (delta != 0)
                  Text(
                    context.tr(
                      delta > 0 ? 'gro_compliance_delta_up' : 'gro_compliance_delta_down',
                      [delta.abs().toStringAsFixed(1)],
                    ),
                    style: TextStyle(color: delta > 0 ? Vx.green : Vx.red, fontSize: 12),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr('gro_breach_monitor', [violations]),
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent / 100),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 6,
                    color: Vx.blue,
                    backgroundColor: p.chip,
                  ),
                ),
                const Icon(Icons.verified_user, color: Vx.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameworkCards extends StatelessWidget {
  const _FrameworkCards({required this.soc2On, required this.violations});

  final bool soc2On;
  final int violations;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    TextStyle title() => TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.ink);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: VxCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock, color: Vx.blue),
                  Text(context.tr('gro_frameworks_title'), style: title()),
                  Text(
                    context.tr(soc2On ? 'gro_frameworks_aligned' : 'gro_frameworks_gap'),
                    style: TextStyle(fontSize: 11, color: soc2On ? Vx.green : Vx.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: VxCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: violations == 0 ? Vx.blue : Vx.red),
                  Text(context.tr('gro_breach_title'), style: title()),
                  Text(
                    context.tr('gro_breach_value', [violations]),
                    style: TextStyle(fontSize: 11, color: violations == 0 ? Vx.green : Vx.red),
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

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.lastAuditDays, required this.daemonChecks});

  final int? lastAuditDays;
  final int daemonChecks;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('gro_protocol_title'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(context.tr('gro_protocol_body'), style: TextStyle(color: p.muted, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              lastAuditDays != null
                  ? context.tr('gro_protocol_reviewed', [lastAuditDays])
                  : context.tr('gro_protocol_never_audited'),
              style: TextStyle(fontSize: 11, color: p.ink),
            ),
          ),
          const SizedBox(height: 10),
          Pill(context.tr('gro_protocol_daemon', [daemonChecks]), bg: p.blueSoft, fg: Vx.blue),
        ],
      ),
    );
  }
}

class _BandwidthRow extends StatelessWidget {
  const _BandwidthRow({required this.row});

  final GovernanceBandwidthRow row;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.tr(row.labelKey), style: TextStyle(fontWeight: FontWeight.w600, color: p.ink)),
              ),
              Text(
                context.tr(row.statusKey),
                style: TextStyle(color: row.overloaded ? Vx.red : Vx.green, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: row.loadPercent / 100,
            color: row.overloaded ? Vx.red : Vx.blue,
            backgroundColor: p.chip,
            borderRadius: BorderRadius.circular(4),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.tr('gro_capacity_percent', [row.loadPercent]),
              style: TextStyle(fontSize: 11, color: p.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizationCard extends StatelessWidget {
  const _OptimizationCard({required this.target, required this.onApply});

  final String? target;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      color: p.blueSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: Vx.blue),
              const SizedBox(width: 8),
              Text(context.tr('gro_optimization_title'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('gro_optimization_body', [target ?? '—']),
              style: TextStyle(fontSize: 12, color: p.ink),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onApply,
            style: FilledButton.styleFrom(backgroundColor: Vx.blue),
            icon: const Icon(Icons.bolt),
            label: Text(context.tr('gro_optimization_apply')),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.capUsd, required this.burn, required this.index});

  final int capUsd;
  final double burn;
  final double index;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final cap = NumberFormat.decimalPattern(context.languageCode).format(capUsd);
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(context.tr('gro_budget_allocation')),
                Text(context.tr('gro_budget_cap', [cap]), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(context.tr('gro_budget_burn')),
                Text(
                  context.tr('gro_budget_burn_value', [burn.toStringAsFixed(1)]),
                  style: TextStyle(fontWeight: FontWeight.w700, color: burn <= 0 ? Vx.green : p.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(context.tr('gro_budget_index')),
                Text(
                  context.tr('gro_budget_index_value', [index.toStringAsFixed(2)]),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Vx.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyToggle extends StatelessWidget {
  const _PolicyToggle({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: p.ink)),
                Text(description, style: TextStyle(fontSize: 12, color: p.muted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  const _EscalationCard({super.key, required this.item, required this.onRisks, required this.onTimeline});

  final GovernanceEscalation item;
  final VoidCallback onRisks;
  final VoidCallback onTimeline;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.projectName, style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.tr(item.detailKey, [item.detailArg]),
              style: TextStyle(color: p.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onRisks,
                  style: FilledButton.styleFrom(backgroundColor: Vx.blue),
                  child: Text(context.tr('gro_governance_open_risks')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTimeline,
                  icon: const Icon(Icons.timeline),
                  label: Text(context.tr('gro_governance_open_timeline')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
