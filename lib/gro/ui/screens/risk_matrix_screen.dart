import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/ui_message_listener.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/gro/ui/gro_ui_extensions.dart';
import 'package:mdeps_flutter/gro/ui/widgets/gro_dialogs.dart';

/// Active risks of a project. Swipe a card right-to-left to resolve it.
class RiskMatrixScreen extends StatefulWidget {
  const RiskMatrixScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<RiskMatrixScreen> createState() => _RiskMatrixScreenState();
}

class _RiskMatrixScreenState extends State<RiskMatrixScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.of(context).gro.loadGovernanceData(widget.projectId);
      }
    });
  }

  Future<void> _addRisk() async {
    final gro = AppScope.of(context).gro;
    final result = await showDialog<(String, String)>(context: context, builder: (_) => const AddRiskDialog());
    if (result != null) {
      await gro.addCustomRisk(widget.projectId, result.$1, result.$2);
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
          title: Text(context.tr('gro_risks_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: context.tr('gro_a11y_add_risk'),
          backgroundColor: Vx.blue,
          foregroundColor: Colors.white,
          onPressed: _addRisk,
          child: const Icon(Icons.add),
        ),
        body: ListenableBuilder(
          listenable: gro,
          builder: (context, _) {
            final risks = gro.activeRisks(widget.projectId);
            if (risks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.tr('gro_empty_risks'), style: TextStyle(fontSize: 16, color: p.muted)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: risks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final risk = risks[i];
                return Semantics(
                  label: context.tr('gro_a11y_swipe_to_resolve'),
                  child: Dismissible(
                    key: ValueKey(risk.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => gro.resolveRisk(risk),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        semanticLabel: context.tr('gro_a11y_swipe_resolve_icon'),
                      ),
                    ),
                    child: RiskCard(risk: risk),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RiskCard extends StatelessWidget {
  const RiskCard({super.key, required this.risk});

  final Risk risk;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final severity = risk.severity.label(context);
    return Semantics(
      label: context.tr('gro_a11y_risk_card'),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      risk.displayTitle(context),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
                  Semantics(
                    label: context.tr('gro_a11y_severity_badge', [severity]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: risk.severity.corporateColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: risk.severity.badgeContentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(risk.displayDescription(context), style: TextStyle(fontSize: 14, color: p.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
