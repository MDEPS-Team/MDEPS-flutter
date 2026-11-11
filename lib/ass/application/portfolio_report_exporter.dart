import 'package:mdeps_flutter/ass/application/analytics_controller.dart';

enum AnalyticsExportFormat { csv, summary }

enum AnalyticsExportRange { last15Days, quarter, semester }

/// Builds the executive export (same rows as the Android exporter). The
/// UI decides how to hand it over (clipboard in this build).
abstract final class PortfolioReportExporter {
  static String fileName(AnalyticsExportFormat format, [DateTime? now]) {
    final t = now ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';
    return 'vantage_pmo_portfolio_$stamp.${format == AnalyticsExportFormat.csv ? 'csv' : 'txt'}';
  }

  static String build({
    required AnalyticsState state,
    required AnalyticsExportRange range,
    required bool includeSquadBreakdown,
    required String Function(String rangeLabel) header,
  }) {
    final rangeLabel = switch (range) {
      AnalyticsExportRange.last15Days => 'last_15_days',
      AnalyticsExportRange.quarter => 'quarter',
      AnalyticsExportRange.semester => 'semester',
    };
    final b = StringBuffer()
      ..writeln(header(rangeLabel))
      ..writeln('efficiency,${state.operativeEfficiency}')
      ..writeln('spi,${state.schedulePerformanceIndex}')
      ..writeln('cpi,${state.costPerformanceIndex}')
      ..writeln('global_progress,${state.globalProgress}')
      ..writeln('critical_risks,${state.activeCriticalRisks}')
      ..writeln('projects_total,${state.totalProjects}')
      ..writeln('projects_on_track,${state.projectsOnTrack}')
      ..writeln('projects_at_risk,${state.projectsAtRisk}')
      ..writeln('projects_moderate,${state.projectsModerateExposure}')
      ..writeln('open_tasks,${state.openTasks}');
    if (includeSquadBreakdown) {
      b
        ..writeln('squad_pto_tasks,${state.completedTasks}/${state.openTasks + state.completedTasks}')
        ..writeln('squad_gro_risks,${state.activeCriticalRisks}');
    }
    for (final a in state.projectsWithHighRisks) {
      b.writeln('risk_project,${a.projectId},${a.projectName},${a.activeHighRiskCount}');
    }
    return b.toString();
  }
}
