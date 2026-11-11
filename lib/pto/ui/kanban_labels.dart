import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

const kanbanAmber = Color(0xFFB7791F);

extension TaskStatusUi on TaskStatus {
  String label(BuildContext context) => context.tr(switch (this) {
        TaskStatus.todo => 'kb_status_todo',
        TaskStatus.inProgress => 'kb_status_in_progress',
        TaskStatus.review => 'kb_status_review',
        TaskStatus.done => 'kb_status_done',
      });

  String shortLabel(BuildContext context) => context.tr(switch (this) {
        TaskStatus.todo => 'kb_status_todo_short',
        TaskStatus.inProgress => 'kb_status_in_progress_short',
        TaskStatus.review => 'kb_status_review_short',
        TaskStatus.done => 'kb_status_done_short',
      });

  Color color(BuildContext context) => switch (this) {
        TaskStatus.todo => context.vx.gray,
        TaskStatus.inProgress => Theme.of(context).colorScheme.primary,
        TaskStatus.review => kanbanAmber,
        TaskStatus.done => Vx.green,
      };
}

extension TaskPriorityUi on TaskPriority {
  String get code => name.toUpperCase();

  String label(BuildContext context) => context.tr(switch (this) {
        TaskPriority.p0 => 'kb_priority_p0',
        TaskPriority.p1 => 'kb_priority_p1',
        TaskPriority.p2 => 'kb_priority_p2',
        TaskPriority.p3 => 'kb_priority_p3',
      });

  Color accent(BuildContext context) => switch (this) {
        TaskPriority.p0 => Vx.red,
        TaskPriority.p1 => kanbanAmber,
        TaskPriority.p2 => Theme.of(context).colorScheme.primary,
        TaskPriority.p3 => context.vx.muted,
      };

  (Color, Color) colors(BuildContext context) {
    final p = context.vx;
    return switch (this) {
      TaskPriority.p0 => (p.redSoft, Vx.red),
      TaskPriority.p1 => (kanbanAmber.withValues(alpha: 0.16), kanbanAmber),
      TaskPriority.p2 => (p.blueSoft, Theme.of(context).colorScheme.primary),
      TaskPriority.p3 => (p.chip, p.muted),
    };
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = priority.colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        priority.code,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

String initialsOf(String? name) {
  final parts = (name ?? '').split(' ').where((s) => s.trim().isNotEmpty).take(2);
  final text = parts.map((s) => s.trim()[0].toUpperCase()).join();
  return text.isEmpty ? '–' : text;
}
