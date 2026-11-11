import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdeps_flutter/ass/application/analytics_controller.dart';
import 'package:mdeps_flutter/ass/application/portfolio_report_exporter.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';

/// "Export executive report" sheet. The generated export is copied to the
/// clipboard (no file-sharing plugin in this build).
class AnalyticsExportSheet extends StatefulWidget {
  const AnalyticsExportSheet({super.key, required this.state});

  final AnalyticsState state;

  @override
  State<AnalyticsExportSheet> createState() => _AnalyticsExportSheetState();
}

class _AnalyticsExportSheetState extends State<AnalyticsExportSheet> {
  AnalyticsExportRange _range = AnalyticsExportRange.quarter;
  AnalyticsExportFormat _format = AnalyticsExportFormat.csv;
  bool _includeSquad = true;

  Future<void> _export() async {
    final text = PortfolioReportExporter.build(
      state: widget.state,
      range: _range,
      includeSquadBreakdown: _includeSquad,
      header: (label) => context.tr('ass_export_file_header', [label]),
    );
    final name = PortfolioReportExporter.fileName(_format);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('${context.tr('ass_export_chooser')} · $name')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Caption(context.tr('ass_export_eyebrow'), color: Vx.blue),
            const SizedBox(height: 4),
            Text(
              context.tr('ass_export_sheet_title'),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.ink),
            ),
            const SizedBox(height: 12),
            Text(context.tr('ass_export_range_label'), style: TextStyle(fontWeight: FontWeight.w600, color: p.ink)),
            const SizedBox(height: 8),
            SegmentedButton<AnalyticsExportRange>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: AnalyticsExportRange.last15Days, label: Text(context.tr('ass_export_range_15d'))),
                ButtonSegment(value: AnalyticsExportRange.quarter, label: Text(context.tr('ass_export_range_quarter'))),
                ButtonSegment(value: AnalyticsExportRange.semester, label: Text(context.tr('ass_export_range_semester'))),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
            const SizedBox(height: 12),
            Text(context.tr('ass_export_format_label'), style: TextStyle(fontWeight: FontWeight.w600, color: p.ink)),
            for (final (format, titleKey, descKey) in const [
              (AnalyticsExportFormat.csv, 'ass_export_format_csv_title', 'ass_export_format_csv_desc'),
              (AnalyticsExportFormat.summary, 'ass_export_format_pdf_title', 'ass_export_format_pdf_desc'),
            ]) ...[
              const SizedBox(height: 12),
              VxCard(
                onTap: () => setState(() => _format = format),
                color: _format == format ? p.blueSoft : p.bg,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    if (_format == format) ...[
                      const Icon(Icons.check_circle, color: Vx.blue),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(titleKey), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                          Text(context.tr(descKey), style: TextStyle(color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _includeSquad = !_includeSquad),
              child: Row(
                children: [
                  Checkbox(value: _includeSquad, onChanged: (v) => setState(() => _includeSquad = v ?? false)),
                  Expanded(child: Text(context.tr('ass_export_include_squad'), style: TextStyle(color: p.ink))),
                ],
              ),
            ),
            Text(context.tr('ass_export_security_note'), style: TextStyle(color: p.muted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('ass_export_cancel')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _export,
                    style: FilledButton.styleFrom(backgroundColor: Vx.blue),
                    child: Text(context.tr('ass_export_download')),
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
