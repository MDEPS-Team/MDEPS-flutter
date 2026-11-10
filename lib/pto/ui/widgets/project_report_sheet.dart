import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

/// Project report preview (replaces the Android `PdfDocument` export): shows
/// the same content the PDF had and lets the user copy it as text.
Future<void> showProjectReportSheet(
  BuildContext context, {
  required Project project,
  required List<Task> tasks,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => _ReportBody(project: project, tasks: tasks, scroll: scroll),
    ),
  );
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.project, required this.tasks, required this.scroll});

  final Project project;
  final List<Task> tasks;
  final ScrollController scroll;

  String _asText(BuildContext context) {
    final b = StringBuffer()
      ..writeln(project.displayName(context))
      ..writeln('${context.tr('pto_project_status_label')}: ${project.status.label(context)}')
      ..writeln()
      ..writeln(project.displayDescription(context))
      ..writeln()
      ..writeln(context.tr('pto_tasks_section_title'));
    for (final t in tasks) {
      b.writeln('${t.isCompleted ? '[x]' : '[ ]'} ${t.displayTitle(context)}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final done = tasks.where((t) => t.isCompleted).length;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Caption(context.tr('pto_a11y_export_pdf'), color: Vx.blue),
        const SizedBox(height: 6),
        Text(
          project.displayName(context),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
        ),
        Text(
          '${context.tr('pto_project_status_label')}: ${project.status.label(context)}',
          style: TextStyle(color: p.muted),
        ),
        const SizedBox(height: 12),
        Text(project.displayDescription(context), style: TextStyle(color: p.ink, height: 1.4)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Caption(context.tr('pto_tasks_section_title'))),
            Text(
              context.tr('pto_hub_tasks_summary', [done, tasks.length]),
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final t in tasks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: t.isCompleted ? Vx.green : p.muted,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(t.displayTitle(context), style: TextStyle(color: p.ink))),
              ],
            ),
          ),
        const SizedBox(height: 20),
        VxButton(
          text: MaterialLocalizations.of(context).copyButtonLabel,
          leadingIcon: Icons.copy,
          style: VxButtonStyle.blue,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _asText(context)));
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
