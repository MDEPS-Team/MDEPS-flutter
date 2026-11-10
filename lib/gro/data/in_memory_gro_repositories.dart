import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';

/// In-memory replacement of the Room `GroDatabase` risk table.
class InMemoryRiskRepository extends ChangeNotifier implements RiskRepository {
  InMemoryRiskRepository({bool seed = true}) {
    if (seed) {
      _seedDemo();
    }
  }

  final List<Risk> _risks = [];
  int _nextId = 1;

  @override
  List<Risk> get risks => List.unmodifiable(_risks);

  @override
  List<Risk> risksOf(int projectId) => _risks.where((r) => r.projectId == projectId).toList();

  @override
  Future<int> insertRisk(Risk risk) async {
    final id = _nextId++;
    _risks.add(risk.copyWith(id: id));
    notifyListeners();
    return id;
  }

  @override
  Future<void> updateRisk(Risk risk) async {
    final i = _risks.indexWhere((r) => r.id == risk.id);
    if (i >= 0) {
      _risks[i] = risk;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteRisk(int riskId) async {
    _risks.removeWhere((r) => r.id == riskId);
    notifyListeners();
  }

  @override
  Future<void> deleteRisksForProject(int projectId) async {
    _risks.removeWhere((r) => r.projectId == projectId);
    notifyListeners();
  }

  /// Project ids match the seed order of `InMemoryProjectRepository`.
  void _seedDemo() {
    void r(int projectId, String title, String description, RiskSeverity severity,
        [RiskStatus status = RiskStatus.identified]) {
      _risks.add(Risk(
        id: _nextId++,
        projectId: projectId,
        title: title,
        description: description,
        severity: severity,
        status: status,
      ));
    }

    r(2, GroSeedContentKeys.riskServerOutage, GroSeedContentKeys.riskServerOutage, RiskSeverity.critical);
    r(2, 'Network validation bottleneck',
        'Firewall rule validations are queued behind a single senior architect.', RiskSeverity.high);
    r(2, 'Vendor SLA for HSM appliances',
        'Hardware security module delivery may slip two weeks.', RiskSeverity.medium, RiskStatus.mitigating);
    r(1, 'Ledger cut-over window',
        'Month-end close overlaps the planned data migration window.', RiskSeverity.high);
    r(1, 'Key-user availability', 'Finance key users are shared with the audit team.', RiskSeverity.low);
    r(3, 'Egress cost overrun', 'Cross-region replication exceeds the FinOps forecast.', RiskSeverity.medium);
    r(4, 'Regulatory interpretation (DORA)',
        'Legal review of data residency clauses still pending.', RiskSeverity.medium);
  }
}

/// In-memory replacement of the Room `GroDatabase` milestone table.
class InMemoryMilestoneRepository extends ChangeNotifier implements MilestoneRepository {
  InMemoryMilestoneRepository({bool seed = true}) {
    if (seed) {
      _seedDemo();
    }
  }

  final List<Milestone> _milestones = [];
  int _nextId = 1;

  @override
  List<Milestone> get milestones => List.unmodifiable(_milestones);

  @override
  List<Milestone> milestonesOf(int projectId) =>
      _milestones.where((m) => m.projectId == projectId).toList();

  @override
  Future<int> insertMilestone(Milestone milestone) async {
    final id = _nextId++;
    _milestones.add(milestone.copyWith(id: id));
    notifyListeners();
    return id;
  }

  @override
  Future<void> updateMilestone(Milestone milestone) async {
    final i = _milestones.indexWhere((m) => m.id == milestone.id);
    if (i >= 0) {
      _milestones[i] = milestone;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteMilestone(int milestoneId) async {
    _milestones.removeWhere((m) => m.id == milestoneId);
    notifyListeners();
  }

  @override
  Future<void> deleteMilestonesForProject(int projectId) async {
    _milestones.removeWhere((m) => m.projectId == projectId);
    notifyListeners();
  }

  void _seedDemo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    void m(int projectId, String title, int days, bool reached) {
      _milestones.add(Milestone(
        id: _nextId++,
        projectId: projectId,
        title: title,
        targetDate: today.add(Duration(days: days)),
        isReached: reached,
      ));
    }

    m(1, GroSeedContentKeys.milestoneArchReview, -12, true);
    m(1, 'Finance UAT gate', 10, false);
    m(1, GroSeedContentKeys.milestoneSteering, 35, false);
    m(2, GroSeedContentKeys.milestoneArchReview, -3, false);
    m(2, 'Segmentation go-live', 18, false);
    m(2, GroSeedContentKeys.milestoneSteering, 40, false);
    m(3, GroSeedContentKeys.milestoneArchReview, -25, true);
    m(3, 'Wave 2 cut-over', 6, false);
    m(4, GroSeedContentKeys.milestoneArchReview, 21, false);
    m(4, GroSeedContentKeys.milestoneSteering, 105, false);
    m(5, 'Go-live', -30, true);
  }
}
