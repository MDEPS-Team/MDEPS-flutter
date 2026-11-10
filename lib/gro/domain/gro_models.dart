import 'package:flutter/foundation.dart';

enum RiskSeverity { low, medium, high, critical }

enum RiskStatus { identified, mitigating, resolved }

/// Stable keys stored as titles for provisioned records; resolved to
/// localized text in the UI.
abstract final class GroSeedContentKeys {
  static const riskServerOutage = 'gro_seed:risk_server_outage';
  static const milestoneArchReview = 'gro_seed:milestone_arch_review';
  static const milestoneSteering = 'gro_seed:milestone_steering';
}

@immutable
class Risk {
  const Risk({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
  });

  final int id;
  final int projectId;
  final String title;
  final String description;
  final RiskSeverity severity;
  final RiskStatus status;

  bool get isActive => status != RiskStatus.resolved;

  bool get isHighOrCritical => severity == RiskSeverity.high || severity == RiskSeverity.critical;

  Risk copyWith({int? id, RiskStatus? status, RiskSeverity? severity}) {
    return Risk(
      id: id ?? this.id,
      projectId: projectId,
      title: title,
      description: description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
    );
  }
}

@immutable
class Milestone {
  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.targetDate,
    required this.isReached,
  });

  final int id;
  final int projectId;
  final String title;
  final DateTime targetDate;
  final bool isReached;

  Milestone copyWith({int? id, bool? isReached, DateTime? targetDate}) {
    return Milestone(
      id: id ?? this.id,
      projectId: projectId,
      title: title,
      targetDate: targetDate ?? this.targetDate,
      isReached: isReached ?? this.isReached,
    );
  }
}

abstract class RiskRepository implements Listenable {
  List<Risk> get risks;

  List<Risk> risksOf(int projectId);

  Future<int> insertRisk(Risk risk);

  Future<void> updateRisk(Risk risk);

  Future<void> deleteRisk(int riskId);

  Future<void> deleteRisksForProject(int projectId);
}

abstract class MilestoneRepository implements Listenable {
  List<Milestone> get milestones;

  List<Milestone> milestonesOf(int projectId);

  Future<int> insertMilestone(Milestone milestone);

  Future<void> updateMilestone(Milestone milestone);

  Future<void> deleteMilestone(int milestoneId);

  Future<void> deleteMilestonesForProject(int projectId);
}
