import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/ass/application/analytics_controller.dart';
import 'package:mdeps_flutter/ass/ui/widgets/analytics_charts.dart';
import 'package:mdeps_flutter/ass/ui/widgets/analytics_export_sheet.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

/// Advanced analytics (intelligence suite): period filter, efficiency trend,
/// SPI/CPI, budget, portfolio health, capacity and risk drill-down.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = AppScope.of(context).analytics;
    final nav = ShellScope.of(context);
    final p = context.vx;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: VxTopBar(
        title: Row(
          children: [
            const Icon(Icons.analytics, size: 22, color: Vx.blue),
            const SizedBox(width: 8),
            Text(context.tr('ass_analytics_title'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
          ],
        ),
        actions: [ProfileButton(tooltip: context.tr('nav_tab_profile'), onTap: () => nav.goTab(AppTab.profile))],
      ),
      body: ListenableBuilder(
        listenable: analytics,
        builder: (context, _) {
          final s = analytics.state;
          return RefreshIndicator(
            onRefresh: () async {
              analytics.markRefreshed();
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  context.tr('portfolio_last_updated', [context.formatTime(analytics.lastRefreshedAt)]),
                  style: TextStyle(fontSize: 11, color: p.muted),
                ),
                const SizedBox(height: 16),
                _Dashboard(
                  state: s,
                  onPeriod: analytics.setPeriod,
                  onExport: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AnalyticsExportSheet(state: s),
                  ),
                  onOpenRisks: () => _showRiskDrillDown(context, s.projectsWithHighRisks, nav),
                  onOpenGovernanceProject: nav.openProjectRisks,
                ),
                const SizedBox(height: 16),
                Text(context.tr('ass_data_disclaimer'), style: TextStyle(fontSize: 12, color: p.muted)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRiskDrillDown(BuildContext context, List<ProjectRiskAlert> alerts, ShellNavigator nav) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final p = sheetContext.vx;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('ass_risk_drilldown_title'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                ),
                if (alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(context.tr('ass_risk_drilldown_empty'), style: TextStyle(color: p.ink)),
                  )
                else
                  for (final a in alerts)
                    InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        nav.openProjectRisks(a.projectId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.tr('ass_risk_drilldown_row', [a.projectName, a.activeHighRiskCount]),
                          style: TextStyle(fontWeight: FontWeight.w600, color: p.ink),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.state,
    required this.onPeriod,
    required this.onExport,
    required this.onOpenRisks,
    required this.onOpenGovernanceProject,
  });

  final AnalyticsState state;
  final ValueChanged<AnalyticsPeriod> onPeriod;
  final VoidCallback onExport;
  final VoidCallback onOpenRisks;
  final ValueChanged<int> onOpenGovernanceProject;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final s = state;
    final money = NumberFormat.decimalPattern(context.languageCode);
    final total = s.totalProjects < 1 ? 1 : s.totalProjects;
    final delta = s.efficiencyDeltaPercent;
    Widget gap() => const SizedBox(height: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Caption(context.tr('ass_intelligence_eyebrow'), color: Vx.blue),
                  Text(
                    context.tr('ass_intelligence_title'),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.file_upload, size: 16),
              label: Text(context.tr('ass_export_action')),
            ),
          ],
        ),
        gap(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in AnalyticsPeriod.values)
              FilterChip(
                selected: s.selectedPeriod == period,
                selectedColor: p.blueSoft,
                checkmarkColor: Vx.blue,
                backgroundColor: p.surface,
                label: Text(context.tr(period.labelKey)),
                onSelected: (_) => onPeriod(period),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('ass_period_active_hint', [context.tr(s.selectedPeriod.labelKey)]),
          style: TextStyle(fontSize: 11, color: p.muted),
        ),
        gap(),
        VxCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Caption(context.tr('ass_efficiency_index_label')),
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: s.operativeEfficiency),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      builder: (context, v, _) => Text(
                        context.tr('ass_efficiency_index_value', [v.toStringAsFixed(1)]),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ),
                  ),
                  if (delta != 0)
                    Pill(
                      context.tr(
                        delta >= 0 ? 'ass_efficiency_delta' : 'ass_efficiency_delta_negative',
                        [delta.abs().toStringAsFixed(1)],
                      ),
                      bg: delta >= 0 ? p.greenSoft : p.redSoft,
                      fg: delta >= 0 ? Vx.green : Vx.red,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 120,
                  child: PortfolioTrendChart(points: s.efficiencyTrend, color: Vx.blue, gridColor: p.line),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final k in const [
                    'ass_chart_bucket_1',
                    'ass_chart_bucket_2',
                    'ass_chart_bucket_3',
                    'ass_chart_bucket_4',
                    'ass_chart_bucket_5',
                  ])
                    Text(context.tr(k), style: TextStyle(fontSize: 11, color: p.muted)),
                ],
              ),
            ],
          ),
        ),
        gap(),
        _KpiRow(
          left: _KpiMini(
            title: context.tr('ass_kpi_spi'),
            value: s.schedulePerformanceIndex.toStringAsFixed(2),
            subtitle: context.tr('ass_kpi_spi_explainer'),
          ),
          right: _KpiMini(
            title: context.tr('ass_kpi_cpi'),
            value: s.costPerformanceIndex.toStringAsFixed(2),
            subtitle: context.tr('ass_kpi_cpi_explainer'),
          ),
        ),
        const SizedBox(height: 8),
        _KpiRow(
          left: _KpiMini(
            title: context.tr('ass_kpi_velocity'),
            value: context.tr('ass_kpi_open_tasks_value', [s.openTasks]),
            subtitle: context.tr('ass_kpi_velocity_sub'),
          ),
          right: _KpiMini(
            title: context.tr('ass_kpi_cycle'),
            value: context.tr('ass_global_progress_value', [(s.globalProgress * 100).toInt()]),
            subtitle: context.tr('ass_kpi_cycle_sub'),
          ),
        ),
        gap(),
        VxCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('ass_budget_title'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.tr('ass_budget_total', [money.format(s.budgetTotalUsd)]),
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: s.budgetCommittedPercent / 100,
                color: Vx.blue,
                backgroundColor: p.chip,
                borderRadius: BorderRadius.circular(4),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.tr('ass_budget_committed', [s.budgetCommittedPercent]),
                  style: TextStyle(fontSize: 11, color: p.muted),
                ),
              ),
              for (final slice in s.budgetSlices)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(context.tr(slice.labelKey), style: TextStyle(fontSize: 12, color: p.ink))),
                      Text(
                        context.tr('ass_budget_slice', [slice.percent, money.format(slice.amountUsd)]),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        gap(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 10,
                child: VxCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        context.tr('ass_portfolio_donut_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox.square(
                          dimension: 100,
                          child: PortfolioDonutChart(percent: s.portfolioHealthPercent, color: Vx.blue, track: p.chip),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          context.tr('ass_portfolio_donut_value', [s.portfolioHealthPercent]),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Vx.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 12,
                child: VxCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('ass_portfolio_health_title'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                      _HealthLegend(context.tr('ass_health_on_track', [s.projectsOnTrack]), s.projectsOnTrack / total, Vx.green),
                      _HealthLegend(
                        context.tr('ass_health_moderate', [s.projectsModerateExposure]),
                        s.projectsModerateExposure / total,
                        const Color(0xFFF9A825),
                      ),
                      _HealthLegend(context.tr('ass_health_critical', [s.projectsAtRisk]), s.projectsAtRisk / total, Vx.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        gap(),
        VxCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('ass_capacity_title'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
              for (final row in s.capacityRows)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 10, child: Text(context.tr(row.labelKey), style: TextStyle(fontSize: 12, color: p.ink))),
                      Expanded(
                        flex: 12,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: LinearProgressIndicator(
                            value: row.loadPercent / 100,
                            backgroundColor: p.chip,
                            borderRadius: BorderRadius.circular(4),
                            color: row.overload
                                ? Vx.red
                                : row.loadPercent >= 85
                                    ? Vx.blue
                                    : Vx.green,
                          ),
                        ),
                      ),
                      Text(
                        context.tr('ass_capacity_percent', [row.loadPercent]),
                        style: TextStyle(fontWeight: FontWeight.w700, color: row.overload ? Vx.red : p.ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (s.topRiskInsight != null) ...[
          gap(),
          VxCard(
            color: p.redSoft,
            borderColor: Colors.transparent,
            onTap: () => onOpenGovernanceProject(s.topRiskInsight!.projectId),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Vx.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('ass_ml_insight_title'),
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr('ass_ml_insight_body', [s.topRiskInsight!.projectName, s.topRiskInsight!.activeHighRiskCount]),
                    style: TextStyle(color: p.ink),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => onOpenGovernanceProject(s.topRiskInsight!.projectId),
                  style: FilledButton.styleFrom(backgroundColor: Vx.blue),
                  child: Text(context.tr('ass_ml_insight_action')),
                ),
              ],
            ),
          ),
        ],
        gap(),
        VxCard(
          onTap: onOpenRisks,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('ass_critical_risks_label'), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
              Semantics(
                label: context.tr('ass_a11y_critical_risks', [s.activeCriticalRisks]),
                child: Text(
                  context.tr('ass_critical_risks_value', [s.activeCriticalRisks]),
                  style: TextStyle(
                    fontSize: 24,
                    color: s.activeCriticalRisks > 0 ? Vx.red : p.ink,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(context.tr('ass_tap_risk_drilldown'), style: TextStyle(color: p.muted)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: left), const SizedBox(width: 8), Expanded(child: right)],
      ),
    );
  }
}

class _KpiMini extends StatelessWidget {
  const _KpiMini({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Caption(title),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: p.ink)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: p.muted)),
        ],
      ),
    );
  }
}

class _HealthLegend extends StatelessWidget {
  const _HealthLegend(this.label, this.fraction, this.color);

  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: p.ink))),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              color: color,
              backgroundColor: p.chip,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
