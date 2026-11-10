import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/ui_message_listener.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/gro/ui/gro_ui_extensions.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/kanban_labels.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';
import 'package:mdeps_flutter/pto/ui/widgets/home_dashboard_widgets.dart';
import 'package:mdeps_flutter/pto/ui/widgets/project_report_sheet.dart';

const _defaultPhaseDays = 30;

enum _PhaseState { done, inFlight, scheduled, planned }

class _Phase {
  _Phase(this.index, this.milestone, this.state, this.date, this.timeProgress, this.overdue);

  final int index;
  final Milestone milestone;
  final _PhaseState state;
  final DateTime date;
  final double timeProgress;
  final bool overdue;
}

/// Quarter as sortable key: year * 10 + quarter.
int _quarterKey(DateTime d) => d.year * 10 + ((d.month - 1) ~/ 3 + 1);

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Milestones → phases: reached ones are "done", the first pending (by date)
/// is "in flight" and the rest are scheduled/planned by proximity.
List<_Phase> _buildPhases(List<Milestone> milestones) {
  final sorted = [...milestones]..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  final now = DateTime.now();
  final today = _dayOf(now);
  final inFlightId = sorted.where((m) => !m.isReached).map((m) => m.id).firstOrNull;
  return [
    for (var i = 0; i < sorted.length; i++)
      () {
        final m = sorted[i];
        final start = i > 0 ? sorted[i - 1].targetDate : m.targetDate.subtract(const Duration(days: _defaultPhaseDays));
        final span = math.max(m.targetDate.difference(start).inMilliseconds, const Duration(days: 1).inMilliseconds);
        final date = _dayOf(m.targetDate);
        final state = m.isReached
            ? _PhaseState.done
            : m.id == inFlightId
                ? _PhaseState.inFlight
                : date.difference(today).inDays <= 45
                    ? _PhaseState.scheduled
                    : _PhaseState.planned;
        return _Phase(
          i + 1,
          m,
          state,
          date,
          m.isReached ? 1 : (now.difference(start).inMilliseconds / span).clamp(0.0, 1.0),
          !m.isReached && date.isBefore(today),
        );
      }(),
  ];
}

Color _stateColor(BuildContext context, _PhaseState s) => switch (s) {
      _PhaseState.done => Vx.green,
      _PhaseState.inFlight => Theme.of(context).colorScheme.primary,
      _PhaseState.scheduled => kanbanAmber,
      _PhaseState.planned => context.vx.muted,
    };

/// Strategic roadmap of a project: quarter filter, velocity, workload and
/// the milestone arc timeline.
class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  int? _quarter;
  bool _quarterInitialized = false;
  Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.of(context).gro.loadGovernanceData(widget.projectId);
      }
    });
  }

  Future<void> _addMilestone() async {
    final result = await showDialog<(String, DateTime)>(
      context: context,
      builder: (_) => const _AddMilestoneDialog(),
    );
    if (result != null && mounted) {
      await AppScope.of(context).gro.addCustomMilestone(widget.projectId, result.$1, result.$2);
      setState(() => _quarter = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final nav = ShellScope.of(context);
    final p = context.vx;
    final fmt = DateFormat('d MMM yyyy', context.languageCode);

    return UiMessageListener(
      messages: services.gro.messages,
      onUndo: services.gro.undoLastAction,
      child: ListenableBuilder(
        listenable: Listenable.merge([services.pto, services.gro]),
        builder: (context, _) {
          final item = services.pto.state.dashboard.items.where((i) => i.project.id == widget.projectId).firstOrNull;
          if (item == null) {
            return Scaffold(backgroundColor: p.bg, body: const Center(child: CircularProgressIndicator()));
          }
          final project = item.project;
          final tasks = services.pto.tasksOf(project.id);
          final blockers = services.gro.activeRisks(project.id).where((r) => r.isHighOrCritical).toList();
          final phases = _buildPhases(services.gro.milestones(project.id));
          final quarters = phases.map((ph) => _quarterKey(ph.date)).toSet().toList()..sort();
          if (!_quarterInitialized) {
            // Default quarter: the one of the in-flight milestone (if any), otherwise "all".
            _quarterInitialized = true;
            final inFlight = phases.where((ph) => ph.state == _PhaseState.inFlight).firstOrNull;
            _quarter = inFlight == null ? null : _quarterKey(inFlight.date);
          }
          final visible = phases.where((ph) => _quarter == null || _quarterKey(ph.date) == _quarter).toList();
          final allExpanded = visible.isNotEmpty && visible.every((ph) => _expanded.contains(ph.milestone.id));
          final primary = Theme.of(context).colorScheme.primary;
          final currentQuarter = _quarterKey(DateTime.now());
          final next = phases.where((ph) => ph.state != _PhaseState.done).firstOrNull;

          return Scaffold(
            backgroundColor: p.bg,
            appBar: AppBar(
              backgroundColor: p.bg,
              leading: IconButton(
                tooltip: context.tr('auth_a11y_back'),
                onPressed: nav.pop,
                icon: Icon(Icons.arrow_back, color: p.ink),
              ),
              titleSpacing: 0,
              title: Text(
                context.tr('rm_title'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
              ),
              actions: [
                IconButton(
                  tooltip: context.tr('rm_a11y_open_kanban'),
                  onPressed: () => nav.openKanban(projectId: project.id),
                  icon: Icon(Icons.view_column_outlined, color: p.ink),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              color: p.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: VxButton(
                          text: context.tr('rm_export_pdf'),
                          style: VxButtonStyle.secondary,
                          leadingIcon: Icons.picture_as_pdf_outlined,
                          height: 50,
                          onPressed: () => showProjectReportSheet(context, project: project, tasks: tasks),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 13,
                        child: VxButton(
                          text: context.tr('rm_add_milestone'),
                          leadingIcon: Icons.add,
                          height: 50,
                          onPressed: _addMilestone,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                StaggeredEnter(
                  index: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Dot(color: Vx.green, size: 7),
                            const SizedBox(width: 6),
                            Caption(context.tr('rm_scope')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                project.displayName(context),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: p.ink),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                project.status.label(context),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            project.displayDescription(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (quarters.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        VxChoiceChip(
                          text: context.tr('rm_all_quarters'),
                          selected: _quarter == null,
                          onTap: () => setState(() => _quarter = null),
                        ),
                        for (final q in quarters) ...[
                          const SizedBox(width: 8),
                          VxChoiceChip(
                            text: q == currentQuarter
                                ? context.tr('rm_quarter_current', [context.tr('rm_quarter', [q % 10, q ~/ 10])])
                                : context.tr('rm_quarter', [q % 10, q ~/ 10]),
                            selected: _quarter == q,
                            onTap: () => setState(() => _quarter = q),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                StaggeredEnter(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _VelocityCard(
                      progress: item.progress,
                      criticalRisks: blockers.length,
                      pendingPhases: phases.where((ph) => ph.state != _PhaseState.done).length,
                      nextDate: next?.date,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEnter(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _WorkloadCard(tasks: tasks, onOpenKanban: () => nav.openKanban(projectId: project.id)),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('rm_arc').toUpperCase(),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: p.ink),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(50)),
                        child: Text(
                          context.tr('rm_phases', [visible.length]),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.muted),
                        ),
                      ),
                      if (visible.isNotEmpty)
                        TextButton.icon(
                          iconAlignment: IconAlignment.end,
                          onPressed: () => setState(() {
                            _expanded = allExpanded ? {} : visible.map((ph) => ph.milestone.id).toSet();
                          }),
                          icon: Icon(allExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: primary),
                          label: Text(
                            context.tr(allExpanded ? 'rm_collapse_all' : 'rm_expand_all'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HomeEmptyCard(
                      icon: Icons.flag,
                      title: context.tr('rm_empty_title'),
                      description: context.tr('rm_empty_desc'),
                      actionLabel: context.tr('rm_add_milestone'),
                      onAction: _addMilestone,
                    ),
                  )
                else
                  for (var i = 0; i < visible.length; i++)
                    StaggeredEnter(
                      key: ValueKey(visible[i].milestone.id),
                      index: i,
                      baseDelayMs: 180,
                      child: _TimelineRow(
                        phase: visible[i],
                        isFirst: i == 0,
                        isLast: i == visible.length - 1,
                        blocker: visible[i].state == _PhaseState.inFlight ? blockers.firstOrNull : null,
                        blockerCount: blockers.length,
                        expanded: _expanded.contains(visible[i].milestone.id),
                        dateFormat: fmt,
                        onToggleExpand: () => setState(() {
                          final id = visible[i].milestone.id;
                          _expanded = _expanded.contains(id) ? (_expanded.toSet()..remove(id)) : {..._expanded, id};
                        }),
                        onToggleReached: () => services.gro.toggleMilestone(visible[i].milestone),
                        onOpenRisks: () => nav.openProjectRisks(project.id),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({
    required this.progress,
    required this.criticalRisks,
    required this.pendingPhases,
    required this.nextDate,
  });

  final double progress;
  final int criticalRisks;
  final int pendingPhases;
  final DateTime? nextDate;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final onTrack = progress >= 0.5 || criticalRisks == 0;
    return _RoadmapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.speed_outlined,
                size: 30,
                iconSize: 17,
                bg: p.blueSoft,
                fg: Theme.of(context).colorScheme.primary,
                radius: 9,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('rm_velocity').toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: p.ink),
                ),
              ),
              const Icon(Icons.trending_up, size: 16, color: Vx.green),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: context.tr('rm_execution'),
                    value: '${(progress * 100).toInt()}%',
                    caption: context.tr(onTrack ? 'rm_on_track' : 'rm_behind'),
                    captionColor: onTrack ? Vx.green : kanbanAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: context.tr('rm_critical_path'),
                    value: '$criticalRisks',
                    caption: context.tr(criticalRisks > 0 ? 'rm_blockers' : 'rm_no_blockers'),
                    captionColor: criticalRisks > 0 ? Vx.red : Vx.green,
                    tint: criticalRisks > 0 ? p.redSoft : null,
                    icon: criticalRisks > 0 ? Icons.warning_amber : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: context.tr('rm_deliveries'),
                    value: '$pendingPhases',
                    caption: nextDate == null
                        ? context.tr('rm_none_pending')
                        : context.tr('rm_next', [DateFormat('d MMM', context.languageCode).format(nextDate!)]),
                    captionColor: p.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.captionColor,
    this.tint,
    this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final Color captionColor;
  final Color? tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: tint ?? p.chip, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.muted),
                ),
              ),
              if (icon != null) Icon(icon, size: 13, color: Vx.red),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          Text(
            caption,
            maxLines: 2,
            style: TextStyle(fontSize: 10, color: captionColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  const _WorkloadCard({required this.tasks, required this.onOpenKanban});

  final List<Task> tasks;
  final VoidCallback onOpenKanban;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final primary = Theme.of(context).colorScheme.primary;
    final total = tasks.isEmpty ? 1 : tasks.length;
    final counts = {
      for (final s in TaskStatus.values) s: tasks.where((t) => t.effectiveStatus == s).length,
    };
    final active = (counts[TaskStatus.inProgress]! + counts[TaskStatus.review]!) * 100 ~/ total;
    return _RoadmapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('rm_workload'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active >= 70 ? p.redSoft : p.chip,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.tr('rm_active_load', [active]),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active >= 70 ? Vx.red : p.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: 10,
              color: p.chip,
              child: tasks.isEmpty
                  ? null
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: VxMotion.easeOut,
                      builder: (context, t, _) => Row(
                        children: [
                          for (final s in const [TaskStatus.done, TaskStatus.review, TaskStatus.inProgress, TaskStatus.todo])
                            if (counts[s]! > 0)
                              Expanded(
                                flex: (counts[s]! * 1000 * t).round().clamp(1, 1000000),
                                child: Container(color: s.color(context)),
                              ),
                          if (t < 1) Expanded(flex: (total * 1000 * (1 - t)).round().clamp(1, 1000000), child: const SizedBox()),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final s in TaskStatus.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Dot(color: s.color(context), size: 7),
                    const SizedBox(width: 4),
                    Text(
                      '${counts[s]} ${s.label(context).toLowerCase()}',
                      style: TextStyle(fontSize: 11, color: p.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onOpenKanban,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('rm_open_kanban'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                    ),
                    Icon(Icons.arrow_forward, size: 14, color: primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.phase,
    required this.isFirst,
    required this.isLast,
    required this.blocker,
    required this.blockerCount,
    required this.expanded,
    required this.dateFormat,
    required this.onToggleExpand,
    required this.onToggleReached,
    required this.onOpenRisks,
  });

  final _Phase phase;
  final bool isFirst;
  final bool isLast;
  final Risk? blocker;
  final int blockerCount;
  final bool expanded;
  final DateFormat dateFormat;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleReached;
  final VoidCallback onOpenRisks;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final color = _stateColor(context, phase.state);
    final filled = phase.state == _PhaseState.done || phase.state == _PhaseState.inFlight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(width: 2, height: 18, color: isFirst ? Colors.transparent : p.line),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: filled ? color : p.chip, shape: BoxShape.circle),
                    child: Icon(
                      switch (phase.state) {
                        _PhaseState.done => Icons.check,
                        _PhaseState.inFlight => Icons.sync,
                        _PhaseState.scheduled => Icons.calendar_today,
                        _PhaseState.planned => Icons.schedule,
                      },
                      size: 15,
                      color: filled ? Colors.white : p.muted,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : phase.state == _PhaseState.done
                              ? Vx.green
                              : p.line,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MilestoneCard(
                  phase: phase,
                  blocker: blocker,
                  blockerCount: blockerCount,
                  expanded: expanded,
                  dateFormat: dateFormat,
                  onToggleExpand: onToggleExpand,
                  onToggleReached: onToggleReached,
                  onOpenRisks: onOpenRisks,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.phase,
    required this.blocker,
    required this.blockerCount,
    required this.expanded,
    required this.dateFormat,
    required this.onToggleExpand,
    required this.onToggleReached,
    required this.onOpenRisks,
  });

  final _Phase phase;
  final Risk? blocker;
  final int blockerCount;
  final bool expanded;
  final DateFormat dateFormat;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleReached;
  final VoidCallback onOpenRisks;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final primary = Theme.of(context).colorScheme.primary;
    final inFlight = phase.state == _PhaseState.inFlight;
    final muted = phase.state == _PhaseState.planned;
    final color = _stateColor(context, phase.state);
    final today = _dayOf(DateTime.now());
    final days = phase.date.difference(today).inDays;
    final done = phase.state == _PhaseState.done;

    final (pillLabel, pillFg, pillBg) = phase.overdue
        ? (context.tr('rm_state_overdue'), Vx.red, p.redSoft)
        : switch (phase.state) {
            _PhaseState.done => (context.tr('rm_state_done'), Vx.green, p.greenSoft),
            _PhaseState.inFlight => (context.tr('rm_state_in_flight'), primary, p.blueSoft),
            _PhaseState.scheduled => (context.tr('rm_state_scheduled'), kanbanAmber, kanbanAmber.withValues(alpha: 0.15)),
            _PhaseState.planned => (context.tr('rm_state_planned'), p.muted, p.chip),
          };

    return Material(
      color: muted ? p.chip.withValues(alpha: 0.5) : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: inFlight ? primary.withValues(alpha: 0.6) : p.line,
          width: inFlight ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleExpand,
        child: AnimatedSize(
          duration: VxMotion.standard,
          curve: VxMotion.easeOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('rm_milestone_n', [phase.index.toString().padLeft(2, '0')]).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: color),
                      ),
                    ),
                    if (inFlight && blockerCount > 0) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: p.redSoft, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            context.tr('rm_critical_path_tag').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Vx.red),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        pillLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pillFg),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    phase.milestone.displayTitle(context),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: muted ? p.ink.withValues(alpha: 0.75) : p.ink,
                    ),
                  ),
                ),
                if (phase.state != _PhaseState.planned)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: phase.timeProgress),
                      duration: const Duration(milliseconds: 700),
                      curve: VxMotion.easeOut,
                      builder: (context, v, _) =>
                          VxProgress(progress: v, color: phase.overdue ? Vx.red : color, height: 6),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        done
                            ? context.tr('rm_completed')
                            : phase.state == _PhaseState.planned
                                ? context.tr('rm_planned_hint')
                                : context.tr('rm_time_elapsed', [(phase.timeProgress * 100).toInt()]),
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ),
                    Text(
                      context.tr('rm_target', [dateFormat.format(phase.date)]),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: phase.overdue ? Vx.red : p.ink,
                      ),
                    ),
                  ],
                ),
                if (blocker != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Material(
                      color: p.redSoft,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onOpenRisks,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lock, size: 14, color: Vx.red),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      context.tr('rm_blocker').toUpperCase(),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Vx.red),
                                    ),
                                  ),
                                  Text(
                                    context.tr('rm_manage'),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Vx.red),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  blocker!.displayTitle(context),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(height: 1, color: p.line),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            done
                                ? context.tr('rm_detail_done')
                                : days < 0
                                    ? context.tr('rm_detail_overdue', [-days])
                                    : days == 0
                                        ? context.tr('rm_detail_today')
                                        : context.tr('rm_detail_days_left', [days]),
                            style: TextStyle(fontSize: 13, color: days < 0 && !done ? Vx.red : p.ink),
                          ),
                        ),
                        const SizedBox(height: 10),
                        VxButton(
                          text: context.tr(done ? 'rm_reopen' : 'rm_mark_reached'),
                          style: done ? VxButtonStyle.secondary : VxButtonStyle.primary,
                          leadingIcon: done ? null : Icons.check,
                          height: 42,
                          onPressed: onToggleReached,
                        ),
                      ],
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

/// "New milestone" dialog. Pops with (title, date).
class _AddMilestoneDialog extends StatefulWidget {
  const _AddMilestoneDialog();

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _title = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 14));

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListenableBuilder(
          listenable: _title,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('rm_add_title'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
              ),
              const SizedBox(height: 14),
              VxTextField(
                controller: _title,
                label: context.tr('rm_field_title'),
                hint: context.tr('rm_field_title_hint'),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: p.line),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      confirmText: context.tr('gro_add_confirm'),
                      cancelText: context.tr('gro_add_cancel'),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: p.muted),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('rm_target', [DateFormat('d MMM yyyy', context.languageCode).format(_date)]),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: VxButton(
                      text: context.tr('gro_add_cancel'),
                      style: VxButtonStyle.secondary,
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VxButton(
                      text: context.tr('gro_add_confirm'),
                      height: 48,
                      enabled: _title.text.trim().isNotEmpty,
                      onPressed: () => Navigator.pop(context, (_title.text.trim(), _date)),
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
