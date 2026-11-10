import 'package:flutter/widgets.dart';
import 'package:mdeps_flutter/ass/application/analytics_controller.dart';
import 'package:mdeps_flutter/core/app_settings.dart';
import 'package:mdeps_flutter/gro/application/gro_controllers.dart';
import 'package:mdeps_flutter/gro/data/in_memory_gro_repositories.dart';
import 'package:mdeps_flutter/iam/application/iam_controllers.dart';
import 'package:mdeps_flutter/iam/data/in_memory_auth_repository.dart';
import 'package:mdeps_flutter/pm/application/profile_controller.dart';
import 'package:mdeps_flutter/pm/data/in_memory_profile_repository.dart';
import 'package:mdeps_flutter/pto/application/pto_controllers.dart';
import 'package:mdeps_flutter/pto/data/in_memory_project_repository.dart';

/// Composition root: owns repositories and long-lived controllers of every
/// bounded context and exposes them to the widget tree.
class AppServices {
  AppServices({bool seedDemoData = true})
      : projectRepository = InMemoryProjectRepository(seed: seedDemoData),
        riskRepository = InMemoryRiskRepository(seed: seedDemoData),
        milestoneRepository = InMemoryMilestoneRepository(seed: seedDemoData) {
    iam = IamController(authRepository);
    pto = PtoController(
      projectRepository: projectRepository,
      riskRepository: riskRepository,
      milestoneRepository: milestoneRepository,
    );
    kanban = KanbanController(projectRepository);
    gro = GroController(
      riskRepository: riskRepository,
      milestoneRepository: milestoneRepository,
      projectRepository: projectRepository,
    );
    governanceHub = GovernanceHubController(
      preferences: governancePreferences,
      projectRepository: projectRepository,
      riskRepository: riskRepository,
      milestoneRepository: milestoneRepository,
    );
    analytics = AnalyticsController(
      projectRepository: projectRepository,
      riskRepository: riskRepository,
      milestoneRepository: milestoneRepository,
    );
    profile = ProfileController(
      authRepository: authRepository,
      profileRepository: profileRepository,
      projectRepository: projectRepository,
      riskRepository: riskRepository,
      milestoneRepository: milestoneRepository,
      governancePreferences: governancePreferences,
    );
    // "Dark Studio" lives in PM preferences but themes the whole app.
    profileRepository.addListener(_syncTheme);
  }

  void _syncTheme() => settings.setDarkStudio(profileRepository.operationalPrefs.darkStudioTheme);

  final settings = AppSettings();

  // IAM
  final authRepository = InMemoryAuthRepository();
  late final IamController iam;

  // PTO
  final InMemoryProjectRepository projectRepository;
  late final PtoController pto;
  late final KanbanController kanban;

  // GRO
  final InMemoryRiskRepository riskRepository;
  final InMemoryMilestoneRepository milestoneRepository;
  final governancePreferences = GovernancePreferencesStore();
  late final GroController gro;
  late final GovernanceHubController governanceHub;

  // ASS
  late final AnalyticsController analytics;

  // PM
  final profileRepository = InMemoryProfileRepository();
  late final ProfileController profile;

  void dispose() {
    profileRepository.removeListener(_syncTheme);
    profile.dispose();
    profileRepository.dispose();
    analytics.dispose();
    governanceHub.dispose();
    gro.dispose();
    kanban.dispose();
    pto.dispose();
    iam.dispose();
    governancePreferences.dispose();
    milestoneRepository.dispose();
    riskRepository.dispose();
    projectRepository.dispose();
    authRepository.dispose();
    settings.dispose();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
