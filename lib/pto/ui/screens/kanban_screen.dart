import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/application/pto_controllers.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/kanban_labels.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';
import 'package:mdeps_flutter/pto/ui/widgets/kanban_create_task.dart';

/// Interactive Kanban board: one page per status column (swipeable) or a
/// compact list; cards move with undo, and tasks are created from a sheet.
class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key, this.initialProjectId});

  final int? initialProjectId;

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final _pager = PageController(viewportFraction: 0.9);
  final _search = TextEditingController();
  bool _compact = false;
  int _page = 0;
  late KanbanController _kanban;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kanban = AppScope.of(context).kanban;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // The initial filter (when coming from a project) is applied once.
      _kanban
        ..setQuery('')
        ..selectProject(widget.initialProjectId);
      _kanban.addListener(_onKanbanChanged);
    });
  }

  @override
  void dispose() {
    _kanban.removeListener(_onKanbanChanged);
    _pager.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onKanbanChanged() {
    final card = _kanban.createdCard;
    if (card != null && mounted && ModalRoute.of(context)?.isCurrent == true) {
      _showCreated(card);
    }
  }

  Future<void> _showCreated(KanbanCard card) async {
    final action = await showDialog<String>(
      context: context,
      builder: (_) => TaskCreatedDialog(card: card),
    );
    _kanban.dismissCreated();
    if (!mounted) {
      return;
    }
    if (action == 'board') {
      setState(() => _compact = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToPage(card.task.effectiveStatus.index));
    } else if (action == 'another') {
      await _openCreate();
    }
  }

  void _goToPage(int index) {
    if (_pager.hasClients) {
      _pager.animateToPage(index, duration: VxMotion.standard, curve: VxMotion.easeOut);
    }
  }

  Future<void> _openCreate() async {
    final services = AppScope.of(context);
    final state = _kanban.state;
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.vx.bg,
      builder: (_) => CreateTaskSheet(
        projects: state.projects,
        preselectedProjectId: state.selectedProjectId,
        defaultAssignee: services.iam.user?.name,
      ),
    );
    if (draft != null) {
      await _kanban.createTask(draft);
    }
  }

  void _move(Task task, TaskStatus target) {
    HapticFeedback.selectionClick();
    final previous = task.effectiveStatus;
    _kanban.moveTask(task, target);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr('kb_moved_to', [target.label(context)])),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: context.tr('kb_undo'),
            onPressed: () => _kanban.moveTask(task.movedTo(target), previous),
          ),
        ),
      );
  }

  void _delete(Task task) {
    _kanban.deleteTask(task);
    showVxSnack(context, context.tr('kb_deleted'));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final nav = ShellScope.of(context);
    return ListenableBuilder(
      listenable: _kanban,
      builder: (context, _) {
        final state = _kanban.state;
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
              context.tr('kb_title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
            ),
            actions: [
              if (state.selectedProjectId != null)
                IconButton(
                  tooltip: context.tr('kb_a11y_open_roadmap'),
                  onPressed: () => nav.openRoadmap(state.selectedProjectId!),
                  icon: Icon(Icons.view_timeline_outlined, color: p.ink),
                ),
              IconButton(
                tooltip: context.tr(_compact ? 'kb_layout_columns' : 'kb_layout_compact'),
                onPressed: () => setState(() => _compact = !_compact),
                icon: Icon(_compact ? Icons.view_column_outlined : Icons.view_list_outlined, color: p.ink),
              ),
            ],
          ),
          bottomNavigationBar: _BottomBar(state: state, onAddTask: _openCreate),
          body: Column(
            children: [
              _SprintHeader(state: state),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _search,
                  onChanged: _kanban.setQuery,
                  style: TextStyle(color: p.ink),
                  decoration: vxInputDecoration(
                    context,
                    hint: context.tr('kb_search_hint'),
                    leadingIcon: Icons.search,
                    suffix: state.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.tr('kb_a11y_clear_search'),
                            onPressed: () {
                              _search.clear();
                              _kanban.setQuery('');
                            },
                            icon: Icon(Icons.close, color: p.muted),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    VxChoiceChip(
                      text: context.tr('kb_all_projects'),
                      selected: state.selectedProjectId == null,
                      onTap: () => _kanban.selectProject(null),
                    ),
                    for (final project in state.projects) ...[
                      const SizedBox(width: 8),
                      VxChoiceChip(
                        text: project.displayName(context),
                        selected: state.selectedProjectId == project.id,
                        onTap: () => _kanban.selectProject(project.id),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _StatusTabs(
                  state: state,
                  selected: _page,
                  highlight: !_compact,
                  onSelect: (i) {
                    if (_compact) {
                      setState(() => _compact = false);
                      WidgetsBinding.instance.addPostFrameCallback((_) => _goToPage(i));
                    } else {
                      _goToPage(i);
                    }
                  },
                ),
              ),
              Expanded(
                child: _compact
                    ? _CompactBoard(state: state, onMove: _move, onDelete: _delete)
                    : PageView.builder(
                        controller: _pager,
                        padEnds: false,
                        itemCount: TaskStatus.values.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6),
                          child: _KanbanColumn(
                            status: TaskStatus.values[i],
                            cards: state.columns[TaskStatus.values[i]] ?? const [],
                            hasFilters: state.query.trim().isNotEmpty,
                            onMove: _move,
                            onDelete: _delete,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SprintHeader extends StatelessWidget {
  const _SprintHeader({required this.state});

  final KanbanState state;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', context.languageCode);
    final week = ((now.difference(DateTime(now.year)).inDays + DateTime(now.year).weekday - 1) ~/ 7) + 1;
    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Dot(color: Vx.green, size: 7),
                    const SizedBox(width: 6),
                    Caption(context.tr('kb_active_sprint')),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.tr('kb_sprint_name', [week, '${fmt.format(start)} – ${fmt.format(end)}']),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(50)),
                child: Text(
                  context.tr('kb_points_progress', [state.donePoints, state.totalPoints]),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.tr('kb_tasks_total', [state.totalTasks]),
                  style: TextStyle(fontSize: 11, color: p.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.state,
    required this.selected,
    required this.highlight,
    required this.onSelect,
  });

  final KanbanState state;
  final int selected;
  final bool highlight;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final status in TaskStatus.values) ...[
            if (status.index > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                button: true,
                selected: highlight && status.index == selected,
                child: GestureDetector(
                  onTap: () => onSelect(status.index),
                  child: AnimatedContainer(
                    duration: VxMotion.fast,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: highlight && status.index == selected ? p.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          status.shortLabel(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                highlight && status.index == selected ? FontWeight.w700 : FontWeight.w500,
                            color: highlight && status.index == selected ? p.ink : p.muted,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: status == TaskStatus.done ? p.greenSoft : p.blueSoft,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${state.count(status)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: status == TaskStatus.done ? Vx.green : primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.cards,
    required this.hasFilters,
    required this.onMove,
    required this.onDelete,
  });

  final TaskStatus status;
  final List<KanbanCard> cards;
  final bool hasFilters;
  final void Function(Task, TaskStatus) onMove;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Dot(color: status.color(context), size: 9),
              const SizedBox(width: 8),
              Text(
                status.label(context).toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: p.ink),
              ),
              Text('  (${cards.length})', style: TextStyle(fontSize: 12, color: p.muted)),
            ],
          ),
        ),
        Expanded(
          child: cards.isEmpty
              ? Align(alignment: Alignment.topCenter, child: _EmptyColumn(status: status, hasFilters: hasFilters))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _TaskCard(
                    key: ValueKey(cards[i].task.id),
                    card: cards[i],
                    onMove: (t) => onMove(cards[i].task, t),
                    onDelete: () => onDelete(cards[i].task),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.status, required this.hasFilters});

  final TaskStatus status;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 28, color: p.gray),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr(
                hasFilters
                    ? 'kb_empty_filtered'
                    : status == TaskStatus.done
                        ? 'kb_empty_done'
                        : 'kb_empty_column',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBoard extends StatelessWidget {
  const _CompactBoard({required this.state, required this.onMove, required this.onDelete});

  final KanbanState state;
  final void Function(Task, TaskStatus) onMove;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        for (final status in TaskStatus.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Dot(color: status.color(context)),
                const SizedBox(width: 8),
                Text(
                  '${status.label(context).toUpperCase()}  ·  ${state.count(status)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: p.muted),
                ),
              ],
            ),
          ),
          for (final card in state.columns[status] ?? const <KanbanCard>[]) ...[
            _TaskCard(
              key: ValueKey(card.task.id),
              card: card,
              compact: true,
              onMove: (t) => onMove(card.task, t),
              onDelete: () => onDelete(card.task),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.card,
    required this.onMove,
    required this.onDelete,
    this.compact = false,
  });

  final KanbanCard card;
  final ValueChanged<TaskStatus> onMove;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final task = card.task;
    final status = task.effectiveStatus;
    final done = status == TaskStatus.done;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 8 : 12, 6, compact ? 8 : 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 12, color: primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          card.projectName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              PriorityBadge(priority: task.priority),
              PopupMenuButton<Object>(
                tooltip: context.tr('kb_a11y_task_menu'),
                icon: Icon(Icons.more_vert, color: p.muted),
                color: p.surface,
                onSelected: (v) => v is TaskStatus ? onMove(v) : onDelete(),
                itemBuilder: (context) => [
                  for (final target in TaskStatus.values.where((s) => s != status))
                    PopupMenuItem<Object>(
                      value: target,
                      child: Row(
                        children: [
                          Dot(color: target.color(context)),
                          const SizedBox(width: 12),
                          Text(context.tr('kb_move_to', [target.label(context)]), style: TextStyle(color: p.ink)),
                        ],
                      ),
                    ),
                  PopupMenuItem<Object>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Vx.red),
                        const SizedBox(width: 12),
                        Text(context.tr('kb_delete'), style: const TextStyle(color: Vx.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: compact ? 2 : 8),
                  child: AnimatedOpacity(
                    opacity: done ? 0.7 : 1,
                    duration: VxMotion.fast,
                    child: Text(
                      task.displayTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: compact ? 14 : 16, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
                ),
                if (!compact && (task.description?.trim().isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (task.dueDate != null) ...[
                      _DueDateLabel(date: task.dueDate!, done: done),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.bolt, size: 14, color: p.muted),
                    Text(context.tr('kb_points', [task.storyPoints]), style: TextStyle(fontSize: 12, color: p.muted)),
                  ],
                ),
                SizedBox(height: compact ? 6 : 12),
                Row(
                  children: [
                    Expanded(child: _AssigneeChip(name: task.assignee, small: compact)),
                    _AdvanceButton(status: status, onMove: onMove, small: compact),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateLabel extends StatelessWidget {
  const _DueDateLabel({required this.date, required this.done});

  final DateTime date;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final now = DateTime.now();
    final overdue = !done && date.isBefore(DateTime(now.year, now.month, now.day));
    final tint = overdue ? Vx.red : p.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, size: 13, color: tint),
        const SizedBox(width: 4),
        Text(
          DateFormat('d MMM', context.languageCode).format(date),
          style: TextStyle(
            fontSize: 12,
            color: tint,
            fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.name, this.small = false});

  final String? name;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final hasName = name?.trim().isNotEmpty ?? false;
    final size = small ? 22.0 : 28.0;
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: p.blueSoft, shape: BoxShape.circle),
          child: Text(
            initialsOf(name),
            style: TextStyle(
              fontSize: small ? 9 : 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            hasName ? name! : context.tr('kb_unassigned'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: small ? 12 : 13, color: hasName ? p.ink : p.muted),
          ),
        ),
      ],
    );
  }
}

/// Advances the card to the next column; on "Done" it reopens the task.
class _AdvanceButton extends StatelessWidget {
  const _AdvanceButton({required this.status, required this.onMove, this.small = false});

  final TaskStatus status;
  final ValueChanged<TaskStatus> onMove;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final next = status.next;
    final target = next ?? TaskStatus.todo;
    final label = next?.shortLabel(context) ?? context.tr('kb_reopen');
    final bg = next == TaskStatus.done ? p.greenSoft : p.chip;
    final fg = next == TaskStatus.done
        ? Vx.green
        : next == null
            ? p.muted
            : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressScale(
        pressedScale: 0.95,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onMove(target),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 5 : 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w700, color: fg)),
                  const SizedBox(width: 4),
                  Icon(
                    next == null
                        ? Icons.replay
                        : next == TaskStatus.done
                            ? Icons.check
                            : Icons.arrow_forward,
                    size: small ? 13 : 15,
                    color: fg,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.onAddTask});

  final KanbanState state;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      color: p.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('kb_burndown'),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.ink),
                        ),
                        Text(
                          context.tr('kb_velocity', [(state.velocity * 100).toInt(), state.donePoints, state.totalPoints]),
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: state.velocity),
                      duration: VxMotion.standard + const Duration(milliseconds: 200),
                      curve: VxMotion.easeOut,
                      builder: (context, v, _) => VxProgress(progress: v, color: Vx.green, height: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              VxButton(
                text: context.tr('kb_add_task'),
                onPressed: onAddTask,
                leadingIcon: Icons.add,
                enabled: state.projects.isNotEmpty,
                height: 50,
              ),
              if (state.projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(context.tr('kb_need_project'), style: TextStyle(fontSize: 11, color: p.muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
