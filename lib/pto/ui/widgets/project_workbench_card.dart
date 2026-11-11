import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

/// Project card with status pill and progress (Home focus list).
class ProjectWorkbenchCard extends StatelessWidget {
  const ProjectWorkbenchCard({
    super.key,
    required this.item,
    required this.onTap,
    this.compact = false,
    this.onDelete,
  });

  final ProjectWithProgress item;
  final VoidCallback onTap;
  final bool compact;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final project = item.project;
    final atRisk = project.status == ProjectStatus.atRisk;
    final accent = atRisk ? Vx.red : Vx.blue;
    final taskSummary = context.tr('pto_project_task_summary', [item.pendingTaskCount, item.totalTaskCount]);

    return Semantics(
      label: context.tr('pto_a11y_project_card'),
      button: true,
      child: VxCard(
        onTap: onTap,
        color: atRisk ? p.redSoft : p.surface,
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (atRisk)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.warning, color: Vx.red),
                  ),
                Expanded(
                  child: Text(
                    project.displayName(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                if (!compact && onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: context.tr('pto_a11y_delete_project'),
                    icon: Icon(Icons.delete, color: p.muted),
                  ),
                Pill(project.status.label(context), bg: atRisk ? p.redSoft : p.blueSoft, fg: accent),
              ],
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  project.displayDescription(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ),
            SizedBox(height: compact ? 10 : 14),
            Row(
              children: [
                Expanded(child: VxProgress(progress: item.progress, color: accent)),
                const SizedBox(width: 10),
                Text(
                  context.tr('pto_project_progress_percent', [(item.progress * 100).toInt()]),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ],
            ),
            if (!compact && item.totalTaskCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(taskSummary, style: TextStyle(fontSize: 11, color: p.muted)),
              ),
            if (compact)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(taskSummary, style: TextStyle(fontSize: 11, color: p.muted))),
                    Icon(Icons.keyboard_arrow_right, color: p.muted),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
