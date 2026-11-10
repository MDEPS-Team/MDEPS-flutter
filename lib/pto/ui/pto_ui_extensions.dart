import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

const _legacyDemoPrefix = 'Demo Project ';
const _legacyDemoDescription = 'Auto-generated project for offline Room testing.';

extension ProjectL10n on Project {
  String displayName(BuildContext context) {
    if (name.startsWith(_legacyDemoPrefix)) {
      return context.tr('pto_demo_project_name', [name.substring(_legacyDemoPrefix.length)]);
    }
    return name;
  }

  String displayDescription(BuildContext context) {
    if (description == _legacyDemoDescription) {
      return context.tr('pto_demo_project_description');
    }
    final brief = stripInitiativeMetadata(description);
    return brief.isEmpty ? context.tr('pto_description_empty') : brief;
  }
}

extension TaskL10n on Task {
  String displayTitle(BuildContext context) => switch (title) {
        'provision:kickoff' => context.tr('pto_provision_task_kickoff'),
        'provision:raci' => context.tr('pto_provision_task_raci'),
        _ => title,
      };
}

extension ProjectStatusL10n on ProjectStatus {
  String label(BuildContext context) => context.tr(switch (this) {
        ProjectStatus.planning => 'pto_status_planning',
        ProjectStatus.inProgress => 'pto_status_in_progress',
        ProjectStatus.atRisk => 'pto_status_at_risk',
        ProjectStatus.completed => 'pto_status_completed',
      });
}

/// Locale-aware date helpers.
extension DateFormatting on BuildContext {
  String formatMediumDate(DateTime date) => DateFormat.yMMMd(languageCode).format(date);

  String formatShortDate(DateTime date) => DateFormat.MMMd(languageCode).format(date);

  String formatLongToday() {
    final text = DateFormat('EEEE, d MMMM yyyy', languageCode).format(DateTime.now());
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  String formatTime(DateTime date) => DateFormat.Hm(languageCode).format(date);
}
