import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/core/application/derived_controller.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

enum AnalyticsPeriod {
  month('ass_period_month'),
  quarter('ass_period_quarter'),
  ytd('ass_period_ytd'),
  custom('ass_period_custom');

  const AnalyticsPeriod(this.labelKey);

  final String labelKey;

  (DateTime, DateTime) range([DateTime? now]) {
    final end = now ?? DateTime.now();
    return switch (this) {
      AnalyticsPeriod.month => (end.subtract(const Duration(days: 30)), end),
      AnalyticsPeriod.quarter => (end.subtract(const Duration(days: 90)), end),
      AnalyticsPeriod.ytd => (DateTime(end.year), end),
      AnalyticsPeriod.custom => (end.subtract(const Duration(days: 45)), end),
    };
  }
}

@immutable
class ProjectRiskAlert {
  const ProjectRiskAlert(this.projectId, this.projectName, this.activeHighRiskCount);

  final int projectId;
  final String projectName;
  final int activeHighRiskCount;
}

@immutable
class AnalyticsBudgetSlice {
  const AnalyticsBudgetSlice(this.labelKey, this.percent, this.amountUsd);

  final String labelKey;
  final int percent;
  final int amountUsd;
}

@immutable
class AnalyticsCapacityRow {
  const AnalyticsCapacityRow(this.labelKey, this.loadPercent, this.overload);

  final String labelKey;
  final int loadPercent;
  final bool overload;
}

@immutable
class AnalyticsState {
  const AnalyticsState({
    this.selectedPeriod = AnalyticsPeriod.month,
    this.operativeEfficiency = 0,
    this.efficiencyDeltaPercent = 0,
    this.efficiencyTrend = const [],
    this.activeCriticalRisks = 0,
    this.globalProgress = 0,
    this.projectsWithHighRisks = const [],
    this.totalProjects = 0,
    this.projectsInProgress = 0,
    this.projectsAtRisk = 0,
    this.projectsCompleted = 0,
    this.projectsOnTrack = 0,
    this.projectsModerateExposure = 0,
    this.schedulePerformanceIndex = 1,
    this.costPerformanceIndex = 1,
    this.openTasks = 0,
    this.completedTasks = 0,
    this.topRiskInsight,
    this.budgetTotalUsd = 0,
    this.budgetCommittedPercent = 0,
    this.budgetSlices = const [],
    this.portfolioHealthPercent = 0,
    this.capacityRows = const [],
  });

  final AnalyticsPeriod selectedPeriod;
  final double operativeEfficiency;
  final double efficiencyDeltaPercent;
  final List<double> efficiencyTrend;
  final int activeCriticalRisks;
  final double globalProgress;
  final List<ProjectRiskAlert> projectsWithHighRisks;
  final int totalProjects;
  final int projectsInProgress;
  final int projectsAtRisk;
  final int projectsCompleted;
  final int projectsOnTrack;
  final int projectsModerateExposure;
  final double schedulePerformanceIndex;
  final double costPerformanceIndex;
  final int openTasks;
  final int completedTasks;
  final ProjectRiskAlert? topRiskInsight;
  final int budgetTotalUsd;
  final int budgetCommittedPercent;
  final List<AnalyticsBudgetSlice> budgetSlices;
  final int portfolioHealthPercent;
  final List<AnalyticsCapacityRow> capacityRows;
}

/// Portfolio analytics KPIs aggregating PTO + GRO (mirrors `AnalyticsViewModel`).
class AnalyticsController extends DerivedController<AnalyticsState> {
  AnalyticsController({
    required this.projectRepository,
    required this.riskRepository,
    required this.milestoneRepository,
  }) : super([projectRepository, riskRepository, milestoneRepository]);

  final ProjectRepository projectRepository;
  final RiskRepository riskRepository;
  final MilestoneRepository milestoneRepository;

  AnalyticsPeriod _period = AnalyticsPeriod.month;
  DateTime lastRefreshedAt = DateTime.now();

  void markRefreshed() {
    lastRefreshedAt = DateTime.now();
    invalidate();
  }

  void setPeriod(AnalyticsPeriod period) {
    _period = period;
    markRefreshed();
  }

  @override
  AnalyticsState build() {
    final tasks = projectRepository.tasks;
    final risks = riskRepository.risks;
    final milestones = milestoneRepository.milestones;
    final projects = projectRepository.projects;
    final (start, end) = _period.range();
    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    final milestonesInPeriod = milestones.where((m) => inRange(m.targetDate)).toList();
    var projectIdsInPeriod = milestonesInPeriod.map((m) => m.projectId).toSet();
    if (projectIdsInPeriod.isEmpty) {
      projectIdsInPeriod = projects.map((p) => p.id).toSet();
    }
    final scopedTasks = tasks.where((t) => projectIdsInPeriod.contains(t.projectId)).toList();
    final scopedProjects = projects.where((p) => projectIdsInPeriod.contains(p.id)).toList();
    final names = {for (final p in projects) p.id: p.name};

    final totalTasks = scopedTasks.length;
    final completedTasks = scopedTasks.where((t) => t.isCompleted).length;
    final efficiency = totalTasks == 0 ? 0.0 : completedTasks / totalTasks * 100;

    final activeHighRisks = risks
        .where((r) => projectIdsInPeriod.contains(r.projectId) && r.isActive && r.isHighOrCritical)
        .toList();
    final byProject = <int, int>{};
    for (final r in activeHighRisks) {
      byProject[r.projectId] = (byProject[r.projectId] ?? 0) + 1;
    }
    final alerts = [
      for (final e in byProject.entries)
        ProjectRiskAlert(e.key, names[e.key] ?? 'Project #${e.key}', e.value),
    ]..sort((a, b) => b.activeHighRiskCount.compareTo(a.activeHighRiskCount));

    final taskProgress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final periodMilestones = milestonesInPeriod.isEmpty ? milestones : milestonesInPeriod;
    final reached = periodMilestones.where((m) => m.isReached).length;
    final milestoneProgress = periodMilestones.isEmpty ? 0.0 : reached / periodMilestones.length;
    final globalProgress = (totalTasks == 0 && periodMilestones.isEmpty)
        ? 0.0
        : totalTasks == 0
            ? milestoneProgress
            : periodMilestones.isEmpty
                ? taskProgress
                : (taskProgress + milestoneProgress) / 2;

    final trend = _efficiencyTrend(periodMilestones, scopedTasks, start, end);
    final delta = trend.length >= 2 ? (trend.last - trend.first) * 100 : 0.0;

    final highRiskIds = activeHighRisks.map((r) => r.projectId).toSet();
    final onTrack = scopedProjects
        .where((p) => p.status == ProjectStatus.inProgress && !highRiskIds.contains(p.id))
        .length;
    final moderate = scopedProjects
        .where((p) => p.status != ProjectStatus.atRisk && highRiskIds.contains(p.id))
        .length;

    // SPI ≈ schedule: milestones reached vs planned in the period (target 1.00).
    final spi = periodMilestones.isEmpty
        ? 0.85 + globalProgress.clamp(0, 1) * 0.2
        : (0.82 + reached / math.max(periodMilestones.length, 1) * 0.36).clamp(0.75, 1.2);
    // CPI ≈ cost/value: task closing efficiency (target 1.00).
    final cpi = (0.86 + efficiency / 100 * 0.18).clamp(0.8, 1.08);

    final (budgetTotal, committed, slices) = _budget(scopedProjects);

    return AnalyticsState(
      selectedPeriod: _period,
      operativeEfficiency: efficiency,
      efficiencyDeltaPercent: delta,
      efficiencyTrend: trend,
      activeCriticalRisks: activeHighRisks.length,
      globalProgress: globalProgress.clamp(0, 1).toDouble(),
      projectsWithHighRisks: alerts,
      totalProjects: scopedProjects.length,
      projectsInProgress: scopedProjects.where((p) => p.status == ProjectStatus.inProgress).length,
      projectsAtRisk: scopedProjects.where((p) => p.status == ProjectStatus.atRisk).length,
      projectsCompleted: scopedProjects.where((p) => p.status == ProjectStatus.completed).length,
      projectsOnTrack: onTrack,
      projectsModerateExposure: moderate,
      schedulePerformanceIndex: spi.toDouble(),
      costPerformanceIndex: cpi.toDouble(),
      openTasks: totalTasks - completedTasks,
      completedTasks: completedTasks,
      topRiskInsight: alerts.firstOrNull,
      budgetTotalUsd: budgetTotal,
      budgetCommittedPercent: committed,
      budgetSlices: slices,
      portfolioHealthPercent:
          scopedProjects.isEmpty ? 0 : (onTrack / scopedProjects.length * 100).toInt(),
      capacityRows: _capacity(scopedProjects, scopedTasks),
    );
  }

  List<double> _efficiencyTrend(
    List<Milestone> milestones,
    List<Task> tasks,
    DateTime start,
    DateTime end, {
    int buckets = 5,
  }) {
    final span = math.max(end.difference(start).inMilliseconds, 1);
    final taskRatio = tasks.isEmpty ? 0.0 : tasks.where((t) => t.isCompleted).length / tasks.length;
    return [
      for (var i = 0; i < buckets; i++)
        () {
          final bucketEnd = start.add(Duration(milliseconds: span * (i + 1) ~/ buckets));
          final due = milestones
              .where((m) => !m.targetDate.isBefore(start) && !m.targetDate.isAfter(bucketEnd))
              .toList();
          return due.isEmpty
              ? taskRatio * ((i + 1) / buckets)
              : due.where((m) => m.isReached).length / due.length;
        }(),
    ];
  }

  (int, int, List<AnalyticsBudgetSlice>) _budget(List<Project> projects) {
    const unit = 80000;
    final total = math.max(projects.length * unit, unit);
    int count(ProjectStatus s) => projects.where((p) => p.status == s).length;
    final inFlight = count(ProjectStatus.inProgress);
    final planning = count(ProjectStatus.planning);
    final atRisk = count(ProjectStatus.atRisk);
    final done = count(ProjectStatus.completed);
    final weightSum = math.max(inFlight * 45 + planning * 30 + atRisk * 15 + done * 10, 1);
    final pDev = inFlight * 45 * 100 ~/ weightSum;
    final pConsult = planning * 30 * 100 ~/ weightSum;
    final pInfra = atRisk * 15 * 100 ~/ weightSum;
    final pCont = math.max(100 - pDev - pConsult - pInfra, 5);
    return (
      total,
      (100 - pCont).clamp(55, 98),
      [
        AnalyticsBudgetSlice('ass_budget_dev', pDev, total * pDev ~/ 100),
        AnalyticsBudgetSlice('ass_budget_consulting', pConsult, total * pConsult ~/ 100),
        AnalyticsBudgetSlice('ass_budget_infra', pInfra, total * pInfra ~/ 100),
        AnalyticsBudgetSlice('ass_budget_contingency', pCont, total * pCont ~/ 100),
      ],
    );
  }

  List<AnalyticsCapacityRow> _capacity(List<Project> projects, List<Task> tasks) {
    const domains = [
      ('backend', 'ass_capacity_backend'),
      ('api', 'ass_capacity_api'),
      ('mobile', 'ass_capacity_mobile'),
      ('data', 'ass_capacity_data'),
    ];
    final openByProject = <int, int>{};
    for (final t in tasks.where((t) => !t.isCompleted)) {
      openByProject[t.projectId] = (openByProject[t.projectId] ?? 0) + 1;
    }
    return [
      for (final (key, label) in domains)
        () {
          final linked = projects.where((p) {
            final tags = parseInitiativeDomains(p.description);
            return (tags.isEmpty && key == 'backend') || tags.contains(key);
          }).toList();
          final open = linked.fold<int>(0, (a, p) => a + (openByProject[p.id] ?? 0));
          final load = linked.isEmpty
              ? 0
              : (open / math.max(linked.length * 3, 1) * 100).toInt().clamp(0, 100);
          return AnalyticsCapacityRow(label, load, load >= 95);
        }(),
    ];
  }
}
