import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';
import 'package:mdeps_flutter/pto/ui/widgets/home_dashboard_widgets.dart';
import 'package:mdeps_flutter/pto/ui/widgets/project_workbench_card.dart';

/// Home dashboard: greeting, quick actions, priority alert, KPIs,
/// projects in focus and the governance agenda.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _focusLimit = 3;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final nav = ShellScope.of(context);
    final p = context.vx;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: VxTopBar(
        title: Row(
          children: [
            const IconBadge(icon: Icons.space_dashboard_outlined, size: 34, iconSize: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('home_brand_eyebrow'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: p.muted,
                  ),
                ),
                Text(
                  context.tr('nav_tab_home'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: services.analytics,
            builder: (context, _) => IconButton(
              tooltip: context.tr('home_a11y_notifications'),
              onPressed: () => nav.goTab(AppTab.governance),
              icon: Badge(
                isLabelVisible: services.analytics.state.activeCriticalRisks > 0,
                smallSize: 9,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Icons.notifications_outlined, color: p.ink),
              ),
            ),
          ),
          ProfileButton(
            tooltip: context.tr('nav_tab_profile'),
            onTap: () => nav.goTab(AppTab.profile),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([services.pto, services.analytics, services.iam]),
        builder: (context, _) {
          final pto = services.pto.state;
          final dashboard = pto.dashboard;
          final milestones = pto.milestoneDigest;
          final analytics = services.analytics.state;
          final user = services.iam.user;

          // At risk first (lowest progress = most urgent), then in-progress with momentum.
          final atRisk = dashboard.items.where((i) => i.project.status == ProjectStatus.atRisk).toList()
            ..sort((a, b) => a.progress.compareTo(b.progress));
          final active = dashboard.items.where((i) => i.project.status == ProjectStatus.inProgress).toList()
            ..sort((a, b) => b.progress.compareTo(a.progress));
          final rest = dashboard.items.where(
            (i) => i.project.status != ProjectStatus.atRisk && i.project.status != ProjectStatus.inProgress,
          );
          final focus = [...atRisk, ...active, ...rest].take(_focusLimit).toList();

          final capacity = analytics.capacityRows.isEmpty
              ? 0
              : analytics.capacityRows.map((r) => r.loadPercent).reduce((a, b) => a + b) ~/
                  analytics.capacityRows.length;
          final overloaded = analytics.capacityRows.where((r) => r.overload).length;
          final hasPortfolio = dashboard.items.isNotEmpty;
          final health = analytics.portfolioHealthPercent;
          final primary = Theme.of(context).colorScheme.primary;

          return RefreshIndicator(
            onRefresh: () async {
              services.pto.markPortfolioRefreshed();
              services.analytics.markRefreshed();
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                StaggeredEnter(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeGreeting(
                        userName: user?.name,
                        userRole: user?.role,
                        efficiencyPercent: analytics.operativeEfficiency.toInt(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          context.tr('portfolio_last_updated', [context.formatTime(services.pto.lastRefreshedAt)]),
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEnter(
                  index: 1,
                  child: HomeActionChips(
                    onNewProject: nav.createProject,
                    onRegisterMilestone: () => nav.goTab(AppTab.governance),
                    onOpenKanban: nav.openKanban,
                    onOpenAnalytics: () => nav.goTab(AppTab.analytics),
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEnter(
                  index: 2,
                  child: PriorityAlertCard(
                    alert: analytics.topRiskInsight,
                    onManage: nav.openProjectRisks,
                    onAllClear: () => nav.goTab(AppTab.analytics),
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEnter(
                  index: 3,
                  child: HomeSectionHeader(
                    eyebrow: context.tr('home_metrics_title'),
                    actionLabel: context.tr('home_metrics_action'),
                    onAction: () => nav.goTab(AppTab.analytics),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: StaggeredEnter(
                        index: 4,
                        child: MetricTile(
                          icon: Icons.folder_open_outlined,
                          iconTint: primary,
                          iconBg: p.blueSoft,
                          value: pto.activeProjectCount,
                          valueSuffix: '',
                          label: context.tr('home_kpi_active_projects_label'),
                          caption: dashboard.atRiskCount > 0
                              ? context.tr('home_metric_critical_phase', [dashboard.atRiskCount])
                              : context.tr('home_metric_no_critical'),
                          captionTone: dashboard.atRiskCount > 0 ? MetricTone.bad : MetricTone.good,
                          tag: context.tr('home_metric_total', [dashboard.items.length]),
                          onTap: () => nav.goTab(AppTab.projects),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StaggeredEnter(
                        index: 5,
                        child: MetricTile(
                          icon: Icons.verified,
                          iconTint: primary,
                          iconBg: p.blueSoft,
                          value: milestones.reached,
                          valueSuffix: ' / ${milestones.total}',
                          label: context.tr('home_metric_milestones'),
                          caption: context.tr('home_metric_milestones_pending', [milestones.pending]),
                          captionTone: MetricTone.neutral,
                          tag: context.tr('home_metric_rate', [(milestones.reachedRate * 100).toInt()]),
                          onTap: () => nav.goTab(AppTab.governance),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: StaggeredEnter(
                        index: 6,
                        child: MetricTile(
                          icon: Icons.monitor_heart,
                          iconTint: Vx.green,
                          iconBg: p.greenSoft,
                          value: health,
                          valueSuffix: '%',
                          label: context.tr('home_metric_health'),
                          caption: context.tr(
                            !hasPortfolio
                                ? 'home_metric_no_data'
                                : health >= 80
                                    ? 'home_metric_health_good'
                                    : health >= 60
                                        ? 'home_metric_health_warn'
                                        : 'home_metric_health_bad',
                          ),
                          captionTone: !hasPortfolio
                              ? MetricTone.neutral
                              : health >= 80
                                  ? MetricTone.good
                                  : health >= 60
                                      ? MetricTone.warn
                                      : MetricTone.bad,
                          onTap: () => nav.goTab(AppTab.analytics),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StaggeredEnter(
                        index: 7,
                        child: MetricTile(
                          icon: Icons.groups,
                          iconTint: primary,
                          iconBg: p.blueSoft,
                          value: capacity,
                          valueSuffix: '%',
                          label: context.tr('home_metric_capacity'),
                          caption: !hasPortfolio
                              ? context.tr('home_metric_no_data')
                              : overloaded > 0
                                  ? context.tr('home_metric_capacity_overload', [overloaded])
                                  : context.tr('home_metric_capacity_balanced'),
                          captionTone: !hasPortfolio
                              ? MetricTone.neutral
                              : overloaded > 0
                                  ? MetricTone.warn
                                  : MetricTone.good,
                          onTap: () => nav.goTab(AppTab.analytics),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                HomeSectionHeader(
                  eyebrow: context.tr('home_focus_eyebrow'),
                  title: context.tr('home_focus_title'),
                  actionLabel: context.tr('home_focus_see_all', [dashboard.items.length]),
                  onAction: () => nav.goTab(AppTab.projects),
                ),
                const SizedBox(height: 14),
                if (focus.isEmpty)
                  HomeEmptyCard(
                    icon: Icons.folder_open_outlined,
                    title: context.tr('home_focus_empty_title'),
                    description: context.tr('home_focus_empty_desc'),
                    actionLabel: context.tr('home_action_new_project'),
                    onAction: nav.createProject,
                  )
                else
                  for (var i = 0; i < focus.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    StaggeredEnter(
                      index: i,
                      baseDelayMs: 200,
                      child: ProjectWorkbenchCard(
                        item: focus[i],
                        onTap: () => nav.openProject(focus[i].project.id),
                      ),
                    ),
                  ],
                const SizedBox(height: 14),
                HomeSectionHeader(
                  eyebrow: context.tr('home_agenda_eyebrow'),
                  title: context.tr('home_agenda_title'),
                  actionLabel: context.tr('home_agenda_count', [milestones.pending]),
                ),
                const SizedBox(height: 14),
                if (milestones.upcoming.isEmpty)
                  HomeEmptyCard(
                    icon: Icons.event_available_outlined,
                    title: context.tr('home_agenda_empty_title'),
                    description: context.tr('home_agenda_empty_desc'),
                  )
                else
                  GovernanceAgenda(items: milestones.upcoming, onOpen: nav.openProjectMilestones),
              ],
            ),
          );
        },
      ),
    );
  }
}
