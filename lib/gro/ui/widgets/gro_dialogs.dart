import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';

/// "Register risk" dialog. Pops with (title, description).
class AddRiskDialog extends StatefulWidget {
  const AddRiskDialog({super.key});

  @override
  State<AddRiskDialog> createState() => _AddRiskDialogState();
}

class _AddRiskDialogState extends State<AddRiskDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('gro_add_risk_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(context.tr('gro_add_risk_hint')),
            ),
            TextField(
              controller: _title,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('gro_add_risk_field_title'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('gro_add_risk_field_desc'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('gro_add_cancel'))),
        TextButton(
          onPressed: _title.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, (_title.text.trim(), _description.text.trim())),
          child: Text(context.tr('gro_add_confirm')),
        ),
      ],
    );
  }
}

/// "Schedule gate" dialog (target date defaults to +7 days). Pops with the title.
class AddMilestoneDialog extends StatefulWidget {
  const AddMilestoneDialog({super.key});

  @override
  State<AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<AddMilestoneDialog> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('gro_add_milestone_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(context.tr('gro_add_milestone_hint')),
          ),
          TextField(
            controller: _title,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: context.tr('gro_add_milestone_field_title'),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('gro_add_cancel'))),
        TextButton(
          onPressed: _title.text.trim().isEmpty ? null : () => Navigator.pop(context, _title.text.trim()),
          child: Text(context.tr('gro_add_confirm')),
        ),
      ],
    );
  }
}
