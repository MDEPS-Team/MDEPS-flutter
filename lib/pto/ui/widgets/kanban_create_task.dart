import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_brand.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/pto/application/pto_controllers.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/kanban_labels.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

/// Usual Fibonacci scale for story points.
const _pointScale = [1, 2, 3, 5, 8, 13];

/// "Create task" bottom sheet. Pops with the [TaskDraft] on submit.
class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({
    super.key,
    required this.projects,
    required this.preselectedProjectId,
    required this.defaultAssignee,
  });

  final List<Project> projects;
  final int? preselectedProjectId;
  final String? defaultAssignee;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  late TaskDraft _draft = TaskDraft(
    projectId: widget.preselectedProjectId ?? (widget.projects.length == 1 ? widget.projects.single.id : null),
    assignee: widget.defaultAssignee ?? '',
  );
  late final _title = TextEditingController();
  late final _description = TextEditingController();
  late final _assignee = TextEditingController(text: _draft.assignee);
  bool _showErrors = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _assignee.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      confirmText: context.tr('gro_add_confirm'),
      cancelText: context.tr('gro_add_cancel'),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(dueDate: picked));
    }
  }

  void _submit() {
    final draft = _draft.copyWith(
      title: _title.text,
      description: _description.text,
      assignee: _assignee.text,
    );
    if (draft.isValid) {
      Navigator.pop(context, draft);
    } else {
      setState(() {
        _draft = draft;
        _showErrors = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final primary = Theme.of(context).colorScheme.primary;
    final required = context.tr('reg_error_required');
    final pointIndex = _pointScale.contains(_draft.storyPoints) ? _pointScale.indexOf(_draft.storyPoints) : 2;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.tr('kb_sheet_eyebrow').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        context.tr('kb_sheet_title'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr('kb_discard'),
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: p.ink),
                ),
              ],
            ),
            const SizedBox(height: 16),
            VxTextField(
              controller: _title,
              label: context.tr('kb_field_title'),
              hint: context.tr('kb_field_title_hint'),
              error: _showErrors && _title.text.trim().isEmpty ? required : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            VxFieldLabel(context.tr('kb_field_project')),
            LayoutBuilder(
              builder: (context, c) => DropdownMenu<int>(
                width: c.maxWidth,
                initialSelection: _draft.projectId,
                leadingIcon: Icon(Icons.folder_open_outlined, color: p.muted),
                hintText: context.tr('reg_select_placeholder'),
                errorText: _showErrors && _draft.projectId == null ? required : null,
                textStyle: TextStyle(color: p.ink),
                menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(p.surface)),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: p.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.ink, width: 1.5),
                  ),
                ),
                onSelected: (id) => setState(() => _draft = _draft.copyWith(projectId: id)),
                dropdownMenuEntries: [
                  for (final project in widget.projects)
                    DropdownMenuEntry(value: project.id, label: project.displayName(context)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            VxFieldLabel(context.tr('kb_field_description')),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              style: TextStyle(color: p.ink),
              decoration: vxInputDecoration(context, hint: context.tr('kb_field_description_hint')),
            ),
            const SizedBox(height: 16),
            VxTextField(
              controller: _assignee,
              label: context.tr('kb_field_assignee'),
              hint: context.tr('kb_unassigned'),
              leadingIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            VxFieldLabel(context.tr('kb_field_priority')),
            Row(
              children: [
                for (final priority in TaskPriority.values) ...[
                  if (priority.index > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _PrioritySegment(
                      priority: priority,
                      selected: _draft.priority == priority,
                      onTap: () => setState(() => _draft = _draft.copyWith(priority: priority)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VxFieldLabel(context.tr('kb_field_due')),
                      _OutlinedBox(
                        onTap: _pickDue,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: p.muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _draft.dueDate == null
                                    ? context.tr('kb_no_due')
                                    : DateFormat('d MMM yyyy', context.languageCode).format(_draft.dueDate!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _draft.dueDate == null ? p.muted : p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VxFieldLabel(context.tr('kb_field_points')),
                      _OutlinedBox(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: context.tr('kb_a11y_less_points'),
                              onPressed: pointIndex > 0
                                  ? () => setState(
                                      () => _draft = _draft.copyWith(storyPoints: _pointScale[pointIndex - 1]))
                                  : null,
                              icon: Icon(Icons.remove, color: p.ink),
                            ),
                            Expanded(
                              child: Text(
                                context.tr('kb_points', [_draft.storyPoints]),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
                              ),
                            ),
                            IconButton(
                              tooltip: context.tr('kb_a11y_more_points'),
                              onPressed: pointIndex < _pointScale.length - 1
                                  ? () => setState(
                                      () => _draft = _draft.copyWith(storyPoints: _pointScale[pointIndex + 1]))
                                  : null,
                              icon: Icon(Icons.add, color: p.ink),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            VxFieldLabel(context.tr('kb_field_status')),
            Wrap(
              spacing: 8,
              children: [
                for (final s in const [TaskStatus.todo, TaskStatus.inProgress])
                  VxChoiceChip(
                    text: s.label(context),
                    selected: _draft.status == s,
                    onTap: () => setState(() => _draft = _draft.copyWith(status: s)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: VxButton(
                    text: context.tr('kb_discard'),
                    style: VxButtonStyle.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 16,
                  child: VxButton(
                    text: context.tr('kb_create_task'),
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedBox extends StatelessWidget {
  const _OutlinedBox({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class _PrioritySegment extends StatelessWidget {
  const _PrioritySegment({required this.priority, required this.selected, required this.onTap});

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final accent = priority.accent(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: VxMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.16) : p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? accent : p.line, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(
                priority.code,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? accent : p.ink),
              ),
              Text(
                priority.label(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Task registered!" success dialog. Pops with 'board', 'another' or null.
class TaskCreatedDialog extends StatelessWidget {
  const TaskCreatedDialog({super.key, required this.card});

  final KanbanCard card;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final task = card.task;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedSuccessMark(size: 64, colors: [Color(0xFF22A06B), Color(0xFF0B7A4B)]),
            StaggeredEnter(
              index: 0,
              baseDelayMs: 380,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  context.tr('kb_created_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
            ),
            StaggeredEnter(
              index: 1,
              baseDelayMs: 380,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.tr('kb_created_desc', [task.effectiveStatus.label(context)]),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ),
            ),
            StaggeredEnter(
              index: 2,
              baseDelayMs: 380,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_open_outlined, size: 13, color: p.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            card.projectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        task.title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        PriorityBadge(priority: task.priority),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, size: 12, color: p.muted),
                              Text(
                                context.tr('kb_points', [task.storyPoints]),
                                style: TextStyle(fontSize: 11, color: p.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEnter(
              index: 3,
              baseDelayMs: 380,
              child: VxButton(
                text: context.tr('kb_view_in_board'),
                leadingIcon: Icons.view_column_outlined,
                onPressed: () => Navigator.pop(context, 'board'),
              ),
            ),
            const SizedBox(height: 8),
            StaggeredEnter(
              index: 4,
              baseDelayMs: 380,
              child: VxButton(
                text: context.tr('kb_create_another'),
                style: VxButtonStyle.secondary,
                leadingIcon: Icons.add,
                onPressed: () => Navigator.pop(context, 'another'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
