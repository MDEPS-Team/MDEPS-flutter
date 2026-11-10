import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';

extension RiskSeverityUi on RiskSeverity {
  Color get corporateColor => switch (this) {
        RiskSeverity.low => const Color(0xFF2E7D32),
        RiskSeverity.medium => const Color(0xFFF9A825),
        RiskSeverity.high => const Color(0xFFEF6C00),
        RiskSeverity.critical => const Color(0xFFC62828),
      };

  Color get badgeContentColor => this == RiskSeverity.medium ? const Color(0xFF1B1B1F) : Colors.white;

  String label(BuildContext context) => context.tr(switch (this) {
        RiskSeverity.low => 'gro_severity_low',
        RiskSeverity.medium => 'gro_severity_medium',
        RiskSeverity.high => 'gro_severity_high',
        RiskSeverity.critical => 'gro_severity_critical',
      });
}

extension RiskStatusUi on RiskStatus {
  String label(BuildContext context) => context.tr(switch (this) {
        RiskStatus.identified => 'gro_status_identified',
        RiskStatus.mitigating => 'gro_status_mitigating',
        RiskStatus.resolved => 'gro_status_resolved',
      });
}

extension RiskL10n on Risk {
  String displayTitle(BuildContext context) => switch (title) {
        GroSeedContentKeys.riskServerOutage || 'Server Outage' =>
          context.tr('gro_seed_risk_server_outage_title'),
        _ => title,
      };

  String displayDescription(BuildContext context) => switch (description) {
        GroSeedContentKeys.riskServerOutage ||
        'Primary data center failover capacity is below SLA during peak load.' =>
          context.tr('gro_seed_risk_server_outage_desc'),
        _ => description,
      };
}

extension MilestoneL10n on Milestone {
  String displayTitle(BuildContext context) => switch (title) {
        GroSeedContentKeys.milestoneArchReview || 'Architecture review gate' =>
          context.tr('gro_seed_milestone_arch_review_title'),
        GroSeedContentKeys.milestoneSteering || 'Executive steering committee' =>
          context.tr('gro_seed_milestone_steering_title'),
        _ => title,
      };
}

String formatGroTargetDate(BuildContext context, DateTime date) {
  final pattern = context.tr('gro_date_format_pattern');
  return DateFormat(pattern, context.languageCode).format(date);
}
