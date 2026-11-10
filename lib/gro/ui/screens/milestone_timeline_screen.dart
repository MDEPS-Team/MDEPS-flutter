import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/ui_message_listener.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/gro/ui/gro_ui_extensions.dart';
import 'package:mdeps_flutter/gro/ui/widgets/gro_dialogs.dart';

const _reachedGreen = Color(0xFF2E7D32);
const _pendingOutline = Color(0xFFBDBDBD);

/// Project gate timeline. Tapping a milestone toggles its reached status.
class MilestoneTimelineScreen extends StatefulWidget {
  const MilestoneTimelineScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<MilestoneTimelineScreen> createState() => _MilestoneTimelineScreenState();
}

class _MilestoneTimelineScreenState extends State<MilestoneTimelineScreen> {
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
    final gro = AppScope.of(context).gro;
    final title = await showDialog<String>(context: context, builder: (_) => const AddMilestoneDialog());
    if (title != null) {
      await gro.addCustomMilestone(widget.projectId, title, DateTime.now().add(const Duration(days: 7)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gro = AppScope.of(context).gro;
    final nav = ShellScope.of(context);
    final p = context.vx;
    return UiMessageListener(
      messages: gro.messages,
      onUndo: gro.undoLastAction,
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          leading: IconButton(
            tooltip: context.tr('gro_a11y_navigate_back'),
            onPressed: nav.pop,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(context.tr('gro_milestones_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: context.tr('gro_a11y_add_milestone'),
          backgroundColor: Vx.blue,
          foregroundColor: Colors.white,
          onPressed: _addMilestone,
          child: const Icon(Icons.add),
        ),
        body: ListenableBuilder(
          listenable: gro,
          builder: (context, _) {
            final milestones = gro.milestones(widget.projectId);
            if (milestones.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.tr('gro_empty_milestones'), style: TextStyle(fontSize: 16, color: p.muted)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: milestones.length,
              itemBuilder: (context, i) => _TimelineItem(
                key: ValueKey(milestones[i].id),
                milestone: milestones[i],
                isLast: i == milestones.length - 1,
                onToggle: () => gro.toggleMilestone(milestones[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({super.key, required this.milestone, required this.isLast, required this.onToggle});

  final Milestone milestone;
  final bool isLast;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final date = formatGroTargetDate(context, milestone.targetDate);
    final title = milestone.displayTitle(context);
    final rowLabel = context.tr(
      milestone.isReached ? 'gro_a11y_milestone_reached' : 'gro_a11y_milestone_pending',
      [title, date],
    );
    return Semantics(
      button: true,
      label: '$rowLabel. ${context.tr('gro_a11y_toggle_milestone')}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    if (milestone.isReached)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: _reachedGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 18, color: Colors.white),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _pendingOutline, width: 2),
                        ),
                      ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 56,
                        margin: const EdgeInsets.only(top: 4),
                        color: p.line,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.ink)),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(date, style: TextStyle(fontSize: 14, color: p.muted)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
