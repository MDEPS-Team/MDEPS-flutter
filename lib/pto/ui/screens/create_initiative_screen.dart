import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

enum _RiskBand {
  low('pto_create_risk_low'),
  moderate('pto_create_risk_moderate'),
  high('pto_create_risk_high');

  const _RiskBand(this.labelKey);

  final String labelKey;
}

enum _Domain {
  backend('pto_create_domain_backend'),
  api('pto_create_domain_api'),
  mobile('pto_create_domain_mobile'),
  data('pto_create_domain_data');

  const _Domain(this.labelKey);

  final String labelKey;
}

/// "Create new initiative" provisioning form.
class CreateInitiativeScreen extends StatefulWidget {
  const CreateInitiativeScreen({super.key, required this.onClose, required this.onCreated});

  final VoidCallback onClose;
  final ValueChanged<int?> onCreated;

  @override
  State<CreateInitiativeScreen> createState() => _CreateInitiativeScreenState();
}

class _CreateInitiativeScreenState extends State<CreateInitiativeScreen> {
  final _name = TextEditingController();
  final _brief = TextEditingController();
  ProjectStatus _status = ProjectStatus.planning;
  bool _governance = true;
  bool _evidence = true;
  _RiskBand _riskBand = _RiskBand.moderate;
  DateTime _start = DateTime.now();
  DateTime _gate = DateTime.now().add(const Duration(days: 105));
  Set<_Domain> _domains = {_Domain.api};
  bool _creating = false;

  @override
  void dispose() {
    _name.dispose();
    _brief.dispose();
    super.dispose();
  }

  String _buildBrief() {
    final flags = [
      'risk=${_riskBand.name}',
      if (_domains.isNotEmpty) 'domains=${_domains.map((d) => d.name).join(',')}',
      'start=${_start.millisecondsSinceEpoch}',
      'gate=${_gate.millisecondsSinceEpoch}',
      if (_governance) 'soc2=on',
      if (_evidence) 'evidence=on',
    ].join(';');
    return [_brief.text.trim(), '[$flags]'].where((s) => s.isNotEmpty).join('\n');
  }

  Future<void> _create() async {
    if (_creating || _name.text.trim().isEmpty) {
      return;
    }
    setState(() => _creating = true);
    final id = await AppScope.of(context).pto.createProject(
          name: _name.text,
          description: _buildBrief(),
          status: _riskBand == _RiskBand.high ? ProjectStatus.atRisk : _status,
          gateDate: _gate,
          seedHighSeverityRisk: _riskBand == _RiskBand.high,
        );
    if (mounted) {
      widget.onCreated(id);
    }
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    Widget chip(String label, bool selected, VoidCallback onTap) => FilterChip(
          selected: selected,
          selectedColor: p.blueSoft,
          checkmarkColor: Vx.blue,
          backgroundColor: p.surface,
          label: Text(label),
          onSelected: (_) => onTap(),
        );

    return Scaffold(
      backgroundColor: p.bg,
      appBar: VxTopBar(
        leading: IconButton(
          tooltip: context.tr('pto_create_cancel'),
          onPressed: widget.onClose,
          icon: const Icon(Icons.close),
        ),
        title: Text(context.tr('pto_create_nav_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListenableBuilder(
            listenable: _name,
            builder: (context, _) => Row(
              children: [
                Expanded(
                  child: TextButton(onPressed: widget.onClose, child: Text(context.tr('pto_create_discard'))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: VxButton(
                    text: context.tr('pto_create_provision'),
                    style: VxButtonStyle.blue,
                    height: 48,
                    enabled: _name.text.trim().isNotEmpty,
                    loading: _creating,
                    onPressed: _create,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VxCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(context.tr('pto_create_eyebrow'), color: Vx.blue),
                Text(
                  context.tr('pto_create_headline'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(context.tr('pto_create_subhead'), style: TextStyle(fontSize: 13, color: p.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FormSection(
            title: context.tr('pto_create_section_identity'),
            icon: Icons.info,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: context.tr('pto_create_name_label'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _brief,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: context.tr('pto_create_description_label'),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormSection(
            title: context.tr('pto_create_section_timeline'),
            icon: Icons.calendar_today,
            children: [
              _DateField(
                label: context.tr('pto_create_start_date'),
                value: context.formatMediumDate(_start),
                onTap: () => _pickDate(_start, (d) => _start = d),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: context.tr('pto_create_gate_date'),
                value: context.formatMediumDate(_gate),
                onTap: () => _pickDate(_gate, (d) => _gate = d),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormSection(
            title: context.tr('pto_create_section_governance'),
            icon: Icons.lock,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in const [ProjectStatus.planning, ProjectStatus.inProgress, ProjectStatus.atRisk])
                    chip(s.label(context), _status == s, () => setState(() => _status = s)),
                ],
              ),
              _SwitchRow(
                title: context.tr('pto_create_soc2_switch'),
                subtitle: context.tr('pto_create_soc2_switch_desc'),
                value: _governance,
                onChanged: (v) => setState(() => _governance = v),
              ),
              _SwitchRow(
                title: context.tr('pto_create_evidence_switch'),
                subtitle: context.tr('pto_create_evidence_switch_desc'),
                value: _evidence,
                onChanged: (v) => setState(() => _evidence = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormSection(
            title: context.tr('pto_create_section_risk'),
            icon: Icons.warning,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _Domain.values)
                    chip(
                      context.tr(d.labelKey),
                      _domains.contains(d),
                      () => setState(() {
                        _domains = _domains.contains(d) ? (_domains.toSet()..remove(d)) : {..._domains, d};
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in _RiskBand.values)
                    chip(context.tr(b.labelKey), _riskBand == b, () => setState(() => _riskBand = b)),
                ],
              ),
              if (_riskBand == _RiskBand.high)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Pill(context.tr('pto_create_risk_hint'), bg: p.redSoft, fg: Vx.red),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Vx.blue),
              const SizedBox(width: 8),
              Expanded(child: Caption(title, color: p.ink)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.date_range, color: Vx.blue),
        ),
        child: Text(value),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: p.ink)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: p.muted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
