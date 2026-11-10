import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/core/application/derived_controller.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

sealed class _UndoAction {}

class _ResolvedRisk extends _UndoAction {
  _ResolvedRisk(this.previous);

  final Risk previous;
}

class _ToggledMilestone extends _UndoAction {
  _ToggledMilestone(this.previous);

  final Milestone previous;
}

/// Risks & milestones of a project (mirrors `GroViewModel`). One shared
/// instance serves every project; methods receive the project id.
class GroController extends ChangeNotifier with UiMessages {
  GroController({
    required this.riskRepository,
    required this.milestoneRepository,
    required this.projectRepository,
  }) {
    riskRepository.addListener(notifyListeners);
    milestoneRepository.addListener(notifyListeners);
    projectRepository.addListener(notifyListeners);
  }

  final RiskRepository riskRepository;
  final MilestoneRepository milestoneRepository;
  final ProjectRepository projectRepository;

  _UndoAction? _pendingUndo;

  /// Active (non-resolved) risks of the project.
  List<Risk> activeRisks(int projectId) =>
      riskRepository.risksOf(projectId).where((r) => r.isActive).toList();

  List<Milestone> milestones(int projectId) =>
      milestoneRepository.milestonesOf(projectId)..sort((a, b) => a.targetDate.compareTo(b.targetDate));

  /// Called when a governance screen opens: dedupes seed rows and provisions
  /// a baseline when the project has no governance data at all.
  Future<void> loadGovernanceData(int projectId) async {
    final cleaned = await _sanitizeDuplicateSeedRecords(projectId);
    if (cleaned > 0) {
      emit(UiMessage('gro_duplicates_cleaned', args: [cleaned]));
    }
    if (riskRepository.risksOf(projectId).isEmpty && milestoneRepository.milestonesOf(projectId).isEmpty) {
      await _ensureBaselineRisk(projectId);
      await _ensureBaselineMilestones(projectId);
    }
  }

  Future<void> resolveRisk(Risk risk) async {
    _pendingUndo = _ResolvedRisk(risk);
    await riskRepository.updateRisk(risk.copyWith(status: RiskStatus.resolved));
    await _syncProjectStatus(risk.projectId);
    emit(const UiMessage('gro_risk_resolved_analytics', canUndo: true));
  }

  Future<void> toggleMilestone(Milestone milestone) async {
    _pendingUndo = _ToggledMilestone(milestone);
    final toggled = milestone.copyWith(isReached: !milestone.isReached);
    await milestoneRepository.updateMilestone(toggled);
    await _syncProjectStatus(milestone.projectId);
    emit(UiMessage(
      toggled.isReached ? 'gro_milestone_reached_analytics' : 'gro_milestone_reopened',
      canUndo: true,
    ));
  }

  Future<void> undoLastAction() async {
    final undo = _pendingUndo;
    if (undo == null) {
      return;
    }
    _pendingUndo = null;
    switch (undo) {
      case _ResolvedRisk(:final previous):
        await riskRepository.updateRisk(previous);
      case _ToggledMilestone(:final previous):
        await milestoneRepository.updateMilestone(previous);
    }
  }

  Future<void> addCustomRisk(
    int projectId,
    String title,
    String description, {
    RiskSeverity severity = RiskSeverity.high,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (riskRepository.risksOf(projectId).any((r) => r.title == trimmed && r.isActive)) {
      emit(const UiMessage('gro_risk_duplicate_title'));
      return;
    }
    await riskRepository.insertRisk(Risk(
      id: 0,
      projectId: projectId,
      title: trimmed,
      description: description.trim(),
      severity: severity,
      status: RiskStatus.identified,
    ));
    if (severity == RiskSeverity.high || severity == RiskSeverity.critical) {
      final project = _project(projectId);
      if (project != null && project.status != ProjectStatus.atRisk) {
        await projectRepository.updateProject(project.copyWith(status: ProjectStatus.atRisk));
      }
    }
    emit(const UiMessage('gro_risk_added'));
  }

  Future<void> addCustomMilestone(int projectId, String title, DateTime targetDate) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (milestoneRepository.milestonesOf(projectId).any((m) => m.title == trimmed)) {
      emit(const UiMessage('gro_milestone_duplicate_title'));
      return;
    }
    await milestoneRepository.insertMilestone(Milestone(
      id: 0,
      projectId: projectId,
      title: trimmed,
      targetDate: targetDate,
      isReached: false,
    ));
    emit(const UiMessage('gro_milestone_added'));
  }

  Future<void> addGovernanceBaseline(int projectId) async {
    final added = await _ensureBaselineRisk(projectId) + await _ensureBaselineMilestones(projectId);
    emit(added == 0
        ? const UiMessage('gro_seed_already_complete')
        : UiMessage('gro_seed_added_items', args: [added]));
  }

  Future<void> addGovernanceRiskEntry(int projectId) async {
    final count = await _ensureBaselineRisk(projectId);
    emit(UiMessage(count == 0 ? 'gro_seed_risk_exists' : 'gro_risk_added'));
  }

  Future<void> addGovernanceMilestoneEntry(int projectId) async {
    final added = await _ensureBaselineMilestones(projectId);
    emit(added == 0
        ? const UiMessage('gro_seed_milestones_exist')
        : UiMessage('gro_seed_added_items', args: [added]));
  }

  Project? _project(int id) {
    for (final p in projectRepository.projects) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  Future<int> _ensureBaselineRisk(int projectId) async {
    final hasSeed = riskRepository
        .risksOf(projectId)
        .any((r) => r.title == GroSeedContentKeys.riskServerOutage && r.isActive);
    if (hasSeed) {
      return 0;
    }
    await riskRepository.insertRisk(Risk(
      id: 0,
      projectId: projectId,
      title: GroSeedContentKeys.riskServerOutage,
      description: GroSeedContentKeys.riskServerOutage,
      severity: RiskSeverity.critical,
      status: RiskStatus.identified,
    ));
    return 1;
  }

  Future<int> _ensureBaselineMilestones(int projectId) async {
    final existing = milestoneRepository.milestonesOf(projectId);
    final now = DateTime.now();
    var added = 0;
    if (existing.every((m) => m.title != GroSeedContentKeys.milestoneArchReview)) {
      await milestoneRepository.insertMilestone(Milestone(
        id: 0,
        projectId: projectId,
        title: GroSeedContentKeys.milestoneArchReview,
        targetDate: now.add(const Duration(days: 14)),
        isReached: false,
      ));
      added++;
    }
    if (existing.every((m) => m.title != GroSeedContentKeys.milestoneSteering)) {
      await milestoneRepository.insertMilestone(Milestone(
        id: 0,
        projectId: projectId,
        title: GroSeedContentKeys.milestoneSteering,
        targetDate: now.add(const Duration(days: 30)),
        isReached: false,
      ));
      added++;
    }
    return added;
  }

  Future<int> _sanitizeDuplicateSeedRecords(int projectId) async {
    var removed = 0;
    final risks = riskRepository.risksOf(projectId)
        .where((r) => r.title == GroSeedContentKeys.riskServerOutage)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final dup in risks.skip(1)) {
      await riskRepository.deleteRisk(dup.id);
      removed++;
    }
    for (final seed in [GroSeedContentKeys.milestoneArchReview, GroSeedContentKeys.milestoneSteering]) {
      final dups = milestoneRepository.milestonesOf(projectId).where((m) => m.title == seed).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      for (final dup in dups.skip(1)) {
        await milestoneRepository.deleteMilestone(dup.id);
        removed++;
      }
    }
    return removed;
  }

  Future<void> _syncProjectStatus(int projectId) async {
    final project = _project(projectId);
    if (project == null) {
      return;
    }
    final active = activeRisks(projectId);
    final ms = milestoneRepository.milestonesOf(projectId);
    final hasCritical = active.any((r) => r.isHighOrCritical);
    final allGatesDone = ms.isNotEmpty && ms.every((m) => m.isReached);
    final newStatus = hasCritical
        ? ProjectStatus.atRisk
        : (allGatesDone && active.isEmpty && project.status == ProjectStatus.atRisk)
            ? ProjectStatus.inProgress
            : project.status;
    if (newStatus != project.status) {
      await projectRepository.updateProject(project.copyWith(status: newStatus));
      emit(const UiMessage('gro_project_status_synced'));
    }
  }

  @override
  void dispose() {
    riskRepository.removeListener(notifyListeners);
    milestoneRepository.removeListener(notifyListeners);
    projectRepository.removeListener(notifyListeners);
    super.dispose();
  }
}

@immutable
class GovernancePolicies {
  const GovernancePolicies({
    this.soc2Enabled = true,
    this.gateReviewsEnabled = true,
    this.budgetGuardrailsEnabled = true,
  });

  final bool soc2Enabled;
  final bool gateReviewsEnabled;
  final bool budgetGuardrailsEnabled;
}

/// Governance preferences (replaces the DataStore `GovernancePreferencesStore`).
class GovernancePreferencesStore extends ChangeNotifier {
  GovernancePolicies _policies = const GovernancePolicies();
  DateTime? _lastAuditAt;

  GovernancePolicies get policies => _policies;
  DateTime? get lastAuditAt => _lastAuditAt;

  void setSoc2(bool v) => _set(GovernancePolicies(
        soc2Enabled: v,
        gateReviewsEnabled: _policies.gateReviewsEnabled,
        budgetGuardrailsEnabled: _policies.budgetGuardrailsEnabled,
      ));

  void setGateReviews(bool v) => _set(GovernancePolicies(
        soc2Enabled: _policies.soc2Enabled,
        gateReviewsEnabled: v,
        budgetGuardrailsEnabled: _policies.budgetGuardrailsEnabled,
      ));

  void setBudgetGuardrails(bool v) => _set(GovernancePolicies(
        soc2Enabled: _policies.soc2Enabled,
        gateReviewsEnabled: _policies.gateReviewsEnabled,
        budgetGuardrailsEnabled: v,
      ));

  void markAuditCompleted(DateTime at) {
    _lastAuditAt = at;
    notifyListeners();
  }

  void _set(GovernancePolicies p) {
    _policies = p;
    notifyListeners();
  }
}

@immutable
class GovernanceBandwidthRow {
  const GovernanceBandwidthRow(this.labelKey, this.loadPercent, this.statusKey, this.overloaded);

  final String labelKey;
  final int loadPercent;
  final String statusKey;
  final bool overloaded;
}

@immutable
class GovernanceEscalation {
  const GovernanceEscalation(this.projectId, this.projectName, this.detailKey, this.detailArg);

  final int projectId;
  final String projectName;
  final String detailKey;
  final int detailArg;
}

@immutable
class GovernanceHubState {
  const GovernanceHubState({
    required this.compliancePercent,
    required this.complianceDelta,
    required this.criticalViolations,
    required this.policies,
    required this.bandwidthRows,
    required this.escalations,
    required this.lastAuditDaysAgo,
    required this.budgetCapUsd,
    required this.burnRatePercent,
    required this.deliveryIndex,
    required this.showOptimizationCard,
    required this.optimizationTargetProject,
  });

  final int compliancePercent;
  final double complianceDelta;
  final int criticalViolations;
  final GovernancePolicies policies;
  final List<GovernanceBandwidthRow> bandwidthRows;
  final List<GovernanceEscalation> escalations;
  final int? lastAuditDaysAgo;
  final int budgetCapUsd;
  final double burnRatePercent;
  final double deliveryIndex;
  final bool showOptimizationCard;
  final String? optimizationTargetProject;
}

/// Portfolio-wide governance hub (mirrors `GovernanceHubViewModel`).
class GovernanceHubController extends DerivedController<GovernanceHubState> with UiMessages {
  GovernanceHubController({
    required this.preferences,
    required this.projectRepository,
    required this.riskRepository,
    required this.milestoneRepository,
  }) : super([preferences, projectRepository, riskRepository, milestoneRepository]);

  final GovernancePreferencesStore preferences;
  final ProjectRepository projectRepository;
  final RiskRepository riskRepository;
  final MilestoneRepository milestoneRepository;

  bool auditInProgress = false;
  int? _previousCompliance;

  @override
  GovernanceHubState build() {
    final policies = preferences.policies;
    final items = mapPortfolio(projectRepository.projects, projectRepository.tasks);
    final risks = riskRepository.risks;
    final milestones = milestoneRepository.milestones;
    final now = DateTime.now();

    final atRiskCount = items.where((i) => i.project.status == ProjectStatus.atRisk).length;
    final criticalRisks = risks.where((r) => r.isActive && r.isHighOrCritical).length;
    final globalProgress =
        items.isEmpty ? 0.0 : items.map((i) => i.progress).reduce((a, b) => a + b) / items.length;
    final overdueGates = policies.gateReviewsEnabled
        ? milestones.where((m) => !m.isReached && m.targetDate.isBefore(now)).length
        : 0;
    final violations =
        criticalRisks + overdueGates + (policies.budgetGuardrailsEnabled && atRiskCount > 0 ? 1 : 0);

    var compliance = 72 + globalProgress * 28;
    compliance -= criticalRisks * 2.2;
    compliance -= atRiskCount * 3.5;
    compliance -= overdueGates * 4;
    compliance += policies.soc2Enabled ? 6 : -10;
    if (policies.budgetGuardrailsEnabled && atRiskCount == 0) {
      compliance += 2;
    }
    final percent = compliance.toInt().clamp(0, 100);
    final delta = _previousCompliance == null ? 0.0 : (percent - _previousCompliance!).toDouble();
    _previousCompliance = percent;

    final highByProject = <int, int>{};
    for (final r in risks.where((r) => r.isActive && r.isHighOrCritical)) {
      highByProject[r.projectId] = (highByProject[r.projectId] ?? 0) + 1;
    }
    final duplicateLoad = () {
      final counts = <int, int>{};
      for (final r in risks.where((r) => r.title == GroSeedContentKeys.riskServerOutage && r.isActive)) {
        counts[r.projectId] = (counts[r.projectId] ?? 0) + 1;
      }
      return counts.values.where((c) => c > 1).length;
    }();
    final lastAudit = preferences.lastAuditAt;

    return GovernanceHubState(
      compliancePercent: percent,
      complianceDelta: delta,
      criticalViolations: violations,
      policies: policies,
      bandwidthRows: [
        _bandwidth('gro_bw_engineering',
            items.where((i) => i.project.status == ProjectStatus.inProgress).toList()),
        _bandwidth('gro_bw_ux', items.where((i) => i.project.status == ProjectStatus.planning).toList()),
        _bandwidth(
          'gro_bw_qa',
          items.where((i) => i.project.status == ProjectStatus.atRisk || i.pendingTaskCount > 0).toList(),
        ),
      ],
      escalations: [
        for (final item in items
            .where((i) => i.project.status == ProjectStatus.atRisk || (highByProject[i.project.id] ?? 0) > 0)
            .take(6))
          (highByProject[item.project.id] ?? 0) > 0
              ? GovernanceEscalation(item.project.id, item.project.name, 'gro_escalation_risks',
                  highByProject[item.project.id]!)
              : GovernanceEscalation(item.project.id, item.project.name, 'gro_escalation_tasks',
                  item.pendingTaskCount),
      ],
      lastAuditDaysAgo: lastAudit == null ? null : math.max(now.difference(lastAudit).inDays, 0),
      budgetCapUsd: math.max(items.length * 80000, 80000),
      burnRatePercent: ((globalProgress - 0.5) * 12).clamp(-8, 6).toDouble(),
      deliveryIndex: (0.85 + globalProgress * 0.3).clamp(0.8, 1.2).toDouble(),
      showOptimizationCard: duplicateLoad > 0 || atRiskCount > 0,
      optimizationTargetProject:
          items.where((i) => i.project.status == ProjectStatus.atRisk).map((i) => i.project.name).firstOrNull,
    );
  }

  GovernanceBandwidthRow _bandwidth(String labelKey, List<ProjectWithProgress> items) {
    if (items.isEmpty) {
      return GovernanceBandwidthRow(labelKey, 0, 'gro_bw_available', false);
    }
    final open = items.fold<int>(0, (a, i) => a + i.pendingTaskCount);
    final load = (open / math.max(items.length * 4, 1) * 100).toInt().clamp(0, 100);
    final status = load >= 88
        ? 'gro_bw_near_capacity'
        : load <= 45
            ? 'gro_bw_available'
            : 'gro_bw_balanced';
    return GovernanceBandwidthRow(labelKey, load, status, load >= 88);
  }

  void setSoc2(bool v) => preferences.setSoc2(v);

  void setGateReviews(bool v) => preferences.setGateReviews(v);

  void setBudgetGuardrails(bool v) => preferences.setBudgetGuardrails(v);

  Future<void> runFullAudit() async {
    if (auditInProgress) {
      return;
    }
    auditInProgress = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    final overdue = milestoneRepository.milestones.where((m) => !m.isReached && m.targetDate.isBefore(now)).length;
    final critical = riskRepository.risks.where((r) => r.isActive && r.isHighOrCritical).length;
    preferences.markAuditCompleted(now);
    auditInProgress = false;
    notifyListeners();
    emit(UiMessage('gro_audit_complete', args: [critical + overdue]));
  }

  Future<void> applyOptimization() async {
    var changes = 0;
    final byProject = <int, List<Risk>>{};
    for (final r in riskRepository.risks.where((r) => r.title == GroSeedContentKeys.riskServerOutage && r.isActive)) {
      byProject.putIfAbsent(r.projectId, () => []).add(r);
    }
    for (final group in byProject.values) {
      for (final dup in group.skip(1)) {
        await riskRepository.updateRisk(dup.copyWith(status: RiskStatus.resolved));
        changes++;
      }
    }
    final openByProject = <int, List<Task>>{};
    for (final t in projectRepository.tasks.where((t) => !t.isCompleted)) {
      openByProject.putIfAbsent(t.projectId, () => []).add(t);
    }
    final ranked = openByProject.values.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final open in ranked.take(2)) {
      await projectRepository.updateTask(open.first.copyWith(isCompleted: true));
      changes++;
    }
    emit(UiMessage('gro_optimization_applied', args: [changes]));
  }
}
