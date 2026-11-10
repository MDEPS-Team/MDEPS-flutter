import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/core/application/derived_controller.dart';
import 'package:mdeps_flutter/gro/application/gro_controllers.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/iam/data/in_memory_auth_repository.dart';
import 'package:mdeps_flutter/iam/domain/iam_models.dart';
import 'package:mdeps_flutter/pm/domain/profile_models.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

@immutable
class ProfilePortfolioMetrics {
  const ProfilePortfolioMetrics({
    this.projectCount = 0,
    this.projectsOnTrack = 0,
    this.slaAdherencePercent = 0,
    this.slaDeltaPercent = 0,
    this.teamMemberCount = 0,
    this.podCount = 1,
  });

  final int projectCount;
  final int projectsOnTrack;
  final double slaAdherencePercent;
  final double slaDeltaPercent;
  final int teamMemberCount;
  final int podCount;
}

@immutable
class ProfileState {
  const ProfileState({
    required this.user,
    required this.metrics,
    required this.auditRecordCount,
    required this.passwordDaysAgo,
    required this.sessionActive,
  });

  final User? user;
  final ProfilePortfolioMetrics metrics;
  final int auditRecordCount;
  final int passwordDaysAgo;
  final bool sessionActive;
}

/// Profile management (mirrors `ProfileViewModel`): portfolio-derived KPIs plus
/// editable operational preferences that are saved explicitly.
class ProfileController extends DerivedController<ProfileState> {
  ProfileController({
    required this.authRepository,
    required this.profileRepository,
    required this.projectRepository,
    required this.riskRepository,
    required this.milestoneRepository,
    required this.governancePreferences,
  })  : _operational = profileRepository.operationalPrefs,
        super([authRepository, profileRepository, projectRepository, riskRepository, milestoneRepository, governancePreferences]);

  final InMemoryAuthRepository authRepository;
  final ProfileRepository profileRepository;
  final ProjectRepository projectRepository;
  final RiskRepository riskRepository;
  final MilestoneRepository milestoneRepository;
  final GovernancePreferencesStore governancePreferences;

  /// Local edits of the preferences (persisted on [saveProfile]).
  ProfileOperationalPrefs _operational;
  String _draftEmail = '';
  bool isSaving = false;

  ProfileOperationalPrefs get operational => _operational;

  String get draftEmail => _draftEmail.trim().isEmpty ? (authRepository.currentUser?.email ?? '') : _draftEmail;

  @override
  ProfileState build() {
    final projects = projectRepository.projects;
    final tasks = projectRepository.tasks;
    final risks = riskRepository.risks;
    final milestones = milestoneRepository.milestones;
    final days = DateTime.now().difference(profileRepository.operationalPrefs.passwordLastUpdatedAt).inDays;
    return ProfileState(
      user: authRepository.currentUser,
      metrics: _metrics(projects, tasks, risks, milestones, governancePreferences.policies),
      auditRecordCount: projects.length + tasks.length + risks.length + milestones.length,
      passwordDaysAgo: days < 0 ? 0 : days,
      sessionActive: authRepository.token != null,
    );
  }

  ProfilePortfolioMetrics _metrics(
    List<Project> projects,
    List<Task> tasks,
    List<Risk> risks,
    List<Milestone> milestones,
    GovernancePolicies policies,
  ) {
    final highRiskIds = risks.where((r) => r.isActive && r.isHighOrCritical).map((r) => r.projectId).toSet();
    final onTrack = projects.where((p) => p.status == ProjectStatus.inProgress && !highRiskIds.contains(p.id)).length;
    final atRisk = projects.where((p) => p.status == ProjectStatus.atRisk).length;
    final items = mapPortfolio(projects, tasks);
    final globalProgress =
        items.isEmpty ? 0.0 : items.map((i) => i.progress).reduce((a, b) => a + b) / items.length;
    final now = DateTime.now();
    final criticalRisks = risks.where((r) => r.isActive && r.isHighOrCritical).length;
    final overdueGates = policies.gateReviewsEnabled
        ? milestones.where((m) => !m.isReached && m.targetDate.isBefore(now)).length
        : 0;
    var compliance = 72 + globalProgress * 28;
    compliance -= criticalRisks * 2.2;
    compliance -= atRisk * 3.5;
    compliance -= overdueGates * 4;
    compliance += policies.soc2Enabled ? 6 : -10;
    if (policies.budgetGuardrailsEnabled && atRisk == 0) {
      compliance += 2;
    }
    final clamped = compliance.clamp(88.0, 100.0);
    final sla = (clamped + globalProgress * 0.15).clamp(90.0, 99.9);
    int count(ProjectStatus s) => projects.where((p) => p.status == s).length;
    final team = (count(ProjectStatus.inProgress) * 8 +
            count(ProjectStatus.planning) * 6 +
            atRisk * 4 +
            count(ProjectStatus.completed) * 2)
        .clamp(4, 128);
    return ProfilePortfolioMetrics(
      projectCount: projects.length,
      projectsOnTrack: onTrack,
      slaAdherencePercent: sla,
      slaDeltaPercent: sla - 98.2,
      teamMemberCount: team,
      podCount: (projects.length ~/ 4).clamp(1, 8),
    );
  }

  void setTimezone(String key) => _edit(_operational.copyWith(timezoneKey: key));

  void setMethodology(ProfileMethodology m) => _edit(_operational.copyWith(methodology: m));

  void setDigest(ProfileDigestFrequency d) => _edit(_operational.copyWith(digest: d));

  /// The theme applies (and persists) immediately, like in the Compose app.
  Future<void> setDarkStudio(bool enabled) async {
    _edit(_operational.copyWith(darkStudioTheme: enabled));
    await profileRepository.saveOperationalPrefs(_operational);
  }

  void setDraftEmail(String email) {
    _draftEmail = email;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    isSaving = true;
    notifyListeners();
    await profileRepository.saveOperationalPrefs(_operational);
    final email = _draftEmail.trim();
    if (email.isNotEmpty && email != authRepository.currentUser?.email) {
      await authRepository.updateUserEmail(email);
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    isSaving = false;
    notifyListeners();
  }

  Future<void> saveAvatar(String reference) => authRepository.saveProfileAvatar(reference);

  String vantageTenantId() {
    final digits = (authRepository.currentUser?.id ?? '').replaceAll(RegExp(r'\D'), '');
    final tail = digits.length > 4 ? digits.substring(digits.length - 4) : digits;
    return '#VNT-${tail.isEmpty ? '9482' : tail}';
  }

  void _edit(ProfileOperationalPrefs prefs) {
    _operational = prefs;
    notifyListeners();
  }
}
