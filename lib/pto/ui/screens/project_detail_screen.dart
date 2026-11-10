import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/ui_message_listener.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';
import 'package:mdeps_flutter/pto/ui/widgets/evidence_camera.dart';
import 'package:mdeps_flutter/pto/ui/widgets/project_report_sheet.dart';

/// Project hub: summary, attention chips, task list with evidence capture
/// and quick actions (task / risk / milestone).
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.of(context).gro.loadGovernanceData(widget.projectId);
      }
    });
  }

  Future<void> _captureEvidence(Task task) async {
    final services = AppScope.of(context);
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const EvidenceCameraScreen()),
    );
    if (path != null) {
      await services.pto.updateTaskEvidence(task, path);
    }
  }

  Future<void> _showQuickActions(List<Task> tasks) async {
    final services = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _QuickActionsSheet(
        onAddTask: () => services.pto.addTask(
          widget.projectId,
          context.tr('pto_new_task_title', [tasks.length + 1]),
        ),
        onAddRisk: (title, description) => services.gro.addCustomRisk(widget.projectId, title, description),
        onAddMilestone: (title) => services.gro.addCustomMilestone(
          widget.projectId,
          title,
          DateTime.now().add(const Duration(days: 7)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final nav = ShellScope.of(context);
    final p = context.vx;

    return UiMessageListener(
      messages: services.gro.messages,
      onUndo: services.gro.undoLastAction,
      child: ListenableBuilder(
        listenable: Listenable.merge([services.pto, services.gro]),
        builder: (context, _) {
          final project = services.pto.projectById(widget.projectId);
          if (project == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final tasks = services.pto.tasksOf(project.id);
          final risks = services.gro.activeRisks(project.id);
          final milestones = services.gro.milestones(project.id);
          final horizon = DateTime.now().add(const Duration(days: 14));
          final pending = tasks.where((t) => !t.isCompleted).length;
          final highRisks = risks.where((r) => r.isHighOrCritical).length;
          final upcoming = milestones.where((m) => !m.isReached && !m.targetDate.isAfter(horizon)).length;

          return Scaffold(
            backgroundColor: p.bg,
            appBar: AppBar(
              leading: IconButton(
                tooltip: context.tr('pto_a11y_navigate_back'),
                onPressed: nav.pop,
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                project.displayName(context),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  tooltip: context.tr('kb_title'),
                  onPressed: () => nav.openKanban(projectId: project.id),
                  icon: const Icon(Icons.view_column_outlined),
                ),
                IconButton(
                  tooltip: context.tr('rm_title'),
                  onPressed: () => nav.openRoadmap(project.id),
                  icon: const Icon(Icons.view_timeline_outlined),
                ),
                IconButton(
                  tooltip: context.tr('pto_a11y_export_pdf'),
                  onPressed: () => showProjectReportSheet(context, project: project, tasks: tasks),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: context.tr('pto_a11y_add_task'),
              backgroundColor: Vx.blue,
              foregroundColor: Colors.white,
              onPressed: () => _showQuickActions(tasks),
              child: const Icon(Icons.add),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _SummaryCard(project: project),
                const SizedBox(height: 12),
                _AttentionHub(
                  pendingTasks: pending,
                  highRisks: highRisks,
                  upcomingMilestones: upcoming,
                  onHighRisks: () => nav.openProjectRisks(project.id),
                  onMilestones: () => nav.openProjectMilestones(project.id),
                ),
                const SizedBox(height: 12),
                DefaultTabController(
                  length: 3,
                  child: Builder(
                    builder: (tabContext) => TabBar(
                      labelColor: Vx.blue,
                      unselectedLabelColor: p.muted,
                      indicatorColor: Vx.blue,
                      onTap: (i) {
                        // Risks and timeline open their own GRO screens; the hub stays on tasks.
                        if (i == 1) {
                          nav.openProjectRisks(project.id);
                        } else if (i == 2) {
                          nav.openProjectMilestones(project.id);
                        }
                        DefaultTabController.of(tabContext).index = 0;
                      },
                      tabs: [
                        Tab(text: context.tr('pto_hub_tab_tasks')),
                        Tab(text: context.tr('pto_hub_tab_risks')),
                        Tab(text: context.tr('pto_hub_tab_timeline')),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.tr('pto_tasks_section_title'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                ),
                if (tasks.isEmpty)
                  Text(context.tr('pto_empty_tasks'), style: TextStyle(fontSize: 15, color: p.muted))
                else
                  for (final task in tasks) ...[
                    _TaskItem(
                      key: ValueKey(task.id),
                      task: task,
                      onToggle: () => services.pto.toggleTaskStatus(task),
                      onCamera: () => _captureEvidence(task),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.displayName(context),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: on),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              context.tr('pto_project_description_label'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: on),
            ),
          ),
          Text(project.displayDescription(context), style: TextStyle(fontSize: 14, color: on)),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${context.tr('pto_project_status_label')}: ${project.status.label(context)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: on),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionHub extends StatelessWidget {
  const _AttentionHub({
    required this.pendingTasks,
    required this.highRisks,
    required this.upcomingMilestones,
    required this.onHighRisks,
    required this.onMilestones,
  });

  final int pendingTasks;
  final int highRisks;
  final int upcomingMilestones;
  final VoidCallback onHighRisks;
  final VoidCallback onMilestones;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    Widget chip(String label, bool on, VoidCallback onTap) => FilterChip(
          selected: on,
          showCheckmark: on,
          checkmarkColor: Vx.blue,
          selectedColor: p.blueSoft,
          backgroundColor: p.surface,
          label: Text(label),
          onSelected: (_) => onTap(),
        );
    return VxCard(
      color: p.chip,
      radius: 14,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('pto_attention_hub_title'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(context.tr('pto_attention_pending_tasks_chip', [pendingTasks]), pendingTasks > 0, () {}),
              chip(context.tr('pto_attention_high_risks_chip', [highRisks]), highRisks > 0, onHighRisks),
              chip(
                context.tr('pto_attention_milestones_chip', [upcomingMilestones]),
                upcomingMilestones > 0,
                onMilestones,
              ),
            ],
          ),
          if (pendingTasks == 0 && highRisks == 0 && upcomingMilestones == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('pto_attention_all_clear'),
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({super.key, required this.task, required this.onToggle, required this.onCamera});

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final hasEvidence = task.evidencePhotoPath?.isNotEmpty ?? false;
    return VxCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Semantics(
            label: context.tr('pto_a11y_task_checkbox'),
            child: Checkbox(
              value: task.isCompleted,
              activeColor: Vx.blue,
              onChanged: (_) => onToggle(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.displayTitle(context),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                  Text(
                    context.tr(task.isCompleted ? 'pto_task_completed' : 'pto_task_pending'),
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hasEvidence) ...[
                        EvidenceThumbnail(
                          path: task.evidencePhotoPath!,
                          semanticLabel: context.tr('pto_a11y_evidence_thumbnail'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          context.tr(hasEvidence ? 'pto_evidence_attached' : 'pto_evidence_missing'),
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr(hasEvidence ? 'pto_a11y_replace_evidence_photo' : 'pto_a11y_take_evidence_photo'),
            onPressed: onCamera,
            icon: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSheet extends StatefulWidget {
  const _QuickActionsSheet({
    required this.onAddTask,
    required this.onAddRisk,
    required this.onAddMilestone,
  });

  final VoidCallback onAddTask;
  final void Function(String title, String description) onAddRisk;
  final ValueChanged<String> onAddMilestone;

  @override
  State<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<_QuickActionsSheet> {
  final _riskTitle = TextEditingController();
  final _riskDescription = TextEditingController();
  final _milestoneTitle = TextEditingController();

  @override
  void dispose() {
    _riskTitle.dispose();
    _riskDescription.dispose();
    _milestoneTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: Vx.blue,
      minimumSize: const Size.fromHeight(44),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ListenableBuilder(
          listenable: Listenable.merge([_riskTitle, _milestoneTitle]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('pto_quick_actions_title'),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.ink),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: buttonStyle,
                onPressed: () {
                  widget.onAddTask();
                  Navigator.pop(context);
                },
                child: Text(context.tr('pto_quick_action_add_task')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _riskTitle,
                decoration: InputDecoration(
                  labelText: context.tr('pto_quick_action_risk_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _riskDescription,
                decoration: InputDecoration(
                  labelText: context.tr('pto_quick_action_risk_description'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: buttonStyle,
                onPressed: _riskTitle.text.trim().isEmpty
                    ? null
                    : () {
                        widget.onAddRisk(_riskTitle.text.trim(), _riskDescription.text.trim());
                        Navigator.pop(context);
                      },
                child: Text(context.tr('pto_quick_action_log_risk')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _milestoneTitle,
                decoration: InputDecoration(
                  labelText: context.tr('pto_quick_action_milestone_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: buttonStyle,
                onPressed: _milestoneTitle.text.trim().isEmpty
                    ? null
                    : () {
                        widget.onAddMilestone(_milestoneTitle.text.trim());
                        Navigator.pop(context);
                      },
                child: Text(context.tr('pto_quick_action_add_milestone')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
