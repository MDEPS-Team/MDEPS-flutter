import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

enum _HubFilter { all, inProgress, critical, completed }

/// "My projects" portfolio hub: KPIs, search, filters and project cards.
class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _search = TextEditingController();
  _HubFilter _filter = _HubFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(ProjectWithProgress item) async {
    final services = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('pto_delete_project_title')),
        content: Text(context.tr('pto_delete_project_message', [item.project.displayName(context)])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('pto_delete_project_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('pto_delete_project_confirm')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await services.pto.deleteProject(item.project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final nav = ShellScope.of(context);
    final p = context.vx;

    return ListenableBuilder(
      listenable: Listenable.merge([services.pto, services.analytics]),
      builder: (context, _) {
        final dashboard = services.pto.state.dashboard;
        final riskCount = {
          for (final a in services.analytics.state.projectsWithHighRisks) a.projectId: a.activeHighRiskCount,
        };
        bool isCritical(ProjectWithProgress i) =>
            i.project.status == ProjectStatus.atRisk || (riskCount[i.project.id] ?? 0) > 0;

        final activeCount = dashboard.items.where((i) => i.project.status != ProjectStatus.completed).length;
        var list = switch (_filter) {
          _HubFilter.all => dashboard.items,
          _HubFilter.inProgress => dashboard.items.where((i) => i.project.status == ProjectStatus.inProgress).toList(),
          _HubFilter.critical => dashboard.items.where(isCritical).toList(),
          _HubFilter.completed => dashboard.items.where((i) => i.project.status == ProjectStatus.completed).toList(),
        };
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          list = list
              .where((i) => i.project.name.toLowerCase().contains(q) || i.project.description.toLowerCase().contains(q))
              .toList();
        }
        list = [...list]
          ..sort((a, b) {
            final r = (riskCount[b.project.id] ?? 0).compareTo(riskCount[a.project.id] ?? 0);
            if (r != 0) {
              return r;
            }
            final ar = a.project.status == ProjectStatus.atRisk ? 1 : 0;
            final br = b.project.status == ProjectStatus.atRisk ? 1 : 0;
            if (ar != br) {
              return ar.compareTo(br);
            }
            return b.progress.compareTo(a.progress);
          });

        final counts = {
          _HubFilter.all: dashboard.items.length,
          _HubFilter.inProgress: dashboard.inProgressCount,
          _HubFilter.critical: dashboard.items.where(isCritical).length,
          _HubFilter.completed: dashboard.completedCount,
        };
        const filterKeys = {
          _HubFilter.all: 'pto_hub_filter_all',
          _HubFilter.inProgress: 'pto_hub_filter_progress',
          _HubFilter.critical: 'pto_hub_filter_critical',
          _HubFilter.completed: 'pto_hub_filter_done',
        };

        return Scaffold(
          backgroundColor: p.bg,
          appBar: VxTopBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('pto_hub_title'),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: p.ink),
                ),
                Text(
                  context.tr('pto_hub_subtitle', [activeCount]),
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: context.tr('kb_title'),
                onPressed: nav.openKanban,
                icon: Icon(Icons.view_column_outlined, color: p.ink),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _HubKpi(
                      title: context.tr('pto_hub_kpi_budget'),
                      value: '${(dashboard.globalProgress * 100).toInt()}%',
                      subtitle: context.tr('pto_hub_kpi_budget_sub'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HubKpi(
                      title: context.tr('pto_hub_kpi_tasks'),
                      value: '${dashboard.items.fold<int>(0, (a, i) => a + i.pendingTaskCount)}',
                      subtitle: context.tr('pto_hub_kpi_tasks_sub'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HubKpi(
                      title: context.tr('pto_hub_kpi_risk'),
                      value: '${dashboard.atRiskCount}',
                      subtitle: context.tr('pto_hub_kpi_risk_sub'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: p.ink),
                decoration: vxInputDecoration(
                  context,
                  hint: context.tr('pto_hub_search_hint'),
                  leadingIcon: Icons.search,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _HubFilter.values) ...[
                      if (f != _HubFilter.all) const SizedBox(width: 8),
                      FilterChip(
                        selected: _filter == f,
                        showCheckmark: false,
                        selectedColor: p.blueSoft,
                        backgroundColor: p.surface,
                        side: BorderSide(color: _filter == f ? Colors.transparent : p.line),
                        label: Text(
                          context.tr(filterKeys[f]!, [counts[f]]),
                          style: TextStyle(color: _filter == f ? Vx.blue : p.ink),
                        ),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (dashboard.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.tr('pto_empty_projects'), style: TextStyle(color: p.muted)),
                )
              else if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('pto_hub_no_filter_results'), style: TextStyle(color: p.muted)),
                      TextButton(
                        onPressed: () => setState(() {
                          _filter = _HubFilter.all;
                          _search.clear();
                        }),
                        child: Text(context.tr('pto_hub_clear_filters')),
                      ),
                    ],
                  ),
                )
              else
                for (final item in list) ...[
                  _HubProjectCard(
                    key: ValueKey(item.project.id),
                    item: item,
                    highRiskCount: riskCount[item.project.id] ?? 0,
                    onOpenBoard: () => nav.openProject(item.project.id),
                    onResolveAlerts: () => nav.openProjectRisks(item.project.id),
                    onOpenAnalytics: () => nav.goTab(AppTab.analytics),
                    onDelete: () => _confirmDelete(item),
                  ),
                  const SizedBox(height: 12),
                ],
              VxCard(
                color: Vx.blue,
                borderColor: Vx.blue,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('pto_hub_cta_title'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.tr('pto_hub_cta_body'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: nav.createProject,
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Vx.blue),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('pto_hub_cta_button')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HubKpi extends StatelessWidget {
  const _HubKpi({required this.title, required this.value, required this.subtitle});

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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Vx.blue)),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: p.muted)),
        ],
      ),
    );
  }
}

class _HubProjectCard extends StatelessWidget {
  const _HubProjectCard({
    super.key,
    required this.item,
    required this.highRiskCount,
    required this.onOpenBoard,
    required this.onResolveAlerts,
    required this.onOpenAnalytics,
    required this.onDelete,
  });

  final ProjectWithProgress item;
  final int highRiskCount;
  final VoidCallback onOpenBoard;
  final VoidCallback onResolveAlerts;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final project = item.project;
    final atRisk = project.status == ProjectStatus.atRisk;
    final done = project.status == ProjectStatus.completed;
    final (tag, bg, fg) = atRisk
        ? (context.tr('pto_hub_tag_at_risk'), p.redSoft, Vx.red)
        : highRiskCount > 0
            ? (context.tr('pto_hub_tag_attention'), p.redSoft, Vx.red)
            : done
                ? (context.tr('pto_hub_tag_done'), p.greenSoft, Vx.green)
                : (context.tr('pto_hub_tag_on_track'), p.blueSoft, Vx.blue);

    return VxCard(
      onTap: onOpenBoard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(tag, bg: bg, fg: fg),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                tooltip: context.tr('pto_a11y_delete_project'),
                icon: Icon(Icons.delete, color: p.muted),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              project.displayName(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: p.ink),
            ),
          ),
          Text(
            project.displayDescription(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: VxProgress(progress: item.progress, color: atRisk ? Vx.red : Vx.blue)),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  context.tr('pto_project_progress_percent', [(item.progress * 100).toInt()]),
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              context.tr('pto_hub_tasks_summary', [item.totalTaskCount - item.pendingTaskCount, item.totalTaskCount]),
              style: TextStyle(color: p.muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          if (atRisk || highRiskCount > 0)
            FilledButton(
              onPressed: onResolveAlerts,
              style: FilledButton.styleFrom(backgroundColor: Vx.blue),
              child: Text(context.tr('pto_hub_action_resolve')),
            )
          else if (done)
            OutlinedButton(onPressed: onOpenAnalytics, child: Text(context.tr('pto_hub_action_report')))
          else
            OutlinedButton(onPressed: onOpenBoard, child: Text(context.tr('pto_hub_action_board'))),
        ],
      ),
    );
  }
}
