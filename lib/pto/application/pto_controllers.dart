import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/core/application/derived_controller.dart';
import 'package:mdeps_flutter/gro/domain/gro_models.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

@immutable
class UpcomingMilestone {
  const UpcomingMilestone(this.milestone, this.projectName);

  final Milestone milestone;
  final String projectName;
}

/// Portfolio milestone summary for Home: progress and upcoming agenda.
@immutable
class MilestoneDigest {
  const MilestoneDigest({this.reached = 0, this.total = 0, this.upcoming = const []});

  final int reached;
  final int total;
  final List<UpcomingMilestone> upcoming;

  int get pending => total - reached;

  double get reachedRate => total == 0 ? 0 : reached / total;
}

@immutable
class PortfolioDashboard {
  const PortfolioDashboard({
    this.items = const [],
    this.globalProgress = 0,
    this.atRiskCount = 0,
    this.inProgressCount = 0,
    this.planningCount = 0,
    this.completedCount = 0,
  });

  final List<ProjectWithProgress> items;
  final double globalProgress;
  final int atRiskCount;
  final int inProgressCount;
  final int planningCount;
  final int completedCount;
}

@immutable
class PtoState {
  const PtoState({
    required this.projects,
    required this.dashboard,
    required this.milestoneDigest,
    required this.activeProjectCount,
    required this.pendingTaskCount,
  });

  final List<Project> projects;
  final PortfolioDashboard dashboard;
  final MilestoneDigest milestoneDigest;
  final int activeProjectCount;
  final int pendingTaskCount;
}

/// Projects & tasks orchestration (mirrors `PtoViewModel`).
class PtoController extends DerivedController<PtoState> {
  PtoController({
    required this.projectRepository,
    required this.riskRepository,
    required this.milestoneRepository,
  }) : super([projectRepository, riskRepository, milestoneRepository]);

  final ProjectRepository projectRepository;
  final RiskRepository riskRepository;
  final MilestoneRepository milestoneRepository;

  static const _upcomingLimit = 4;
  static const provisionTaskKickoff = 'provision:kickoff';
  static const provisionTaskRaci = 'provision:raci';

  DateTime lastRefreshedAt = DateTime.now();

  void markPortfolioRefreshed() {
    lastRefreshedAt = DateTime.now();
    invalidate();
  }

  @override
  PtoState build() {
    final projects = projectRepository.projects;
    final items = mapPortfolio(projects, projectRepository.tasks);
    final names = {for (final p in projects) p.id: p.name};
    final scoped = milestoneRepository.milestones.where((m) => names.containsKey(m.projectId)).toList();
    final upcoming = scoped.where((m) => !m.isReached).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    return PtoState(
      projects: projects,
      dashboard: PortfolioDashboard(
        items: items,
        globalProgress: items.isEmpty
            ? 0
            : items.map((i) => i.progress).reduce((a, b) => a + b) / items.length,
        atRiskCount: projects.where((p) => p.status == ProjectStatus.atRisk).length,
        inProgressCount: projects.where((p) => p.status == ProjectStatus.inProgress).length,
        planningCount: projects.where((p) => p.status == ProjectStatus.planning).length,
        completedCount: projects.where((p) => p.status == ProjectStatus.completed).length,
      ),
      milestoneDigest: MilestoneDigest(
        reached: scoped.where((m) => m.isReached).length,
        total: scoped.length,
        upcoming: [
          for (final m in upcoming.take(_upcomingLimit)) UpcomingMilestone(m, names[m.projectId]!),
        ],
      ),
      activeProjectCount: projectRepository.activeProjectCount,
      pendingTaskCount: projectRepository.pendingTaskCount,
    );
  }

  Project? projectById(int id) {
    for (final p in projectRepository.projects) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  List<Task> tasksOf(int projectId) => projectRepository.tasksOf(projectId);

  Future<int?> createProject({
    required String name,
    required String description,
    ProjectStatus status = ProjectStatus.planning,
    DateTime? gateDate,
    bool seedHighSeverityRisk = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final id = await projectRepository.insertProject(
      Project(id: 0, name: trimmed, description: description.trim(), status: status),
    );
    await _provisionArtifacts(
      projectId: id,
      gateDate: gateDate,
      seedHighSeverityRisk: seedHighSeverityRisk || status == ProjectStatus.atRisk,
    );
    markPortfolioRefreshed();
    return id;
  }

  Future<void> _provisionArtifacts({
    required int projectId,
    required DateTime? gateDate,
    required bool seedHighSeverityRisk,
  }) async {
    final now = DateTime.now();
    await milestoneRepository.insertMilestone(Milestone(
      id: 0,
      projectId: projectId,
      title: GroSeedContentKeys.milestoneArchReview,
      targetDate: now.add(const Duration(days: 21)),
      isReached: false,
    ));
    await milestoneRepository.insertMilestone(Milestone(
      id: 0,
      projectId: projectId,
      title: GroSeedContentKeys.milestoneSteering,
      targetDate: gateDate ?? now.add(const Duration(days: 105)),
      isReached: false,
    ));
    await projectRepository.insertTask(
      Task(id: 0, projectId: projectId, title: provisionTaskKickoff, isCompleted: false),
    );
    await projectRepository.insertTask(
      Task(id: 0, projectId: projectId, title: provisionTaskRaci, isCompleted: false),
    );
    if (seedHighSeverityRisk) {
      await riskRepository.insertRisk(Risk(
        id: 0,
        projectId: projectId,
        title: GroSeedContentKeys.riskServerOutage,
        description: GroSeedContentKeys.riskServerOutage,
        severity: RiskSeverity.high,
        status: RiskStatus.identified,
      ));
    }
  }

  Future<void> updateProject(Project project) => projectRepository.updateProject(project);

  Future<void> deleteProject(int projectId) async {
    await riskRepository.deleteRisksForProject(projectId);
    await milestoneRepository.deleteMilestonesForProject(projectId);
    await projectRepository.deleteProject(projectId);
  }

  Future<void> addTask(int projectId, String title) => projectRepository.insertTask(
        Task(id: 0, projectId: projectId, title: title, isCompleted: false),
      );

  Future<void> toggleTaskStatus(Task task) =>
      projectRepository.updateTask(task.copyWith(isCompleted: !task.isCompleted));

  Future<void> updateTaskEvidence(Task task, String photoPath) =>
      projectRepository.updateTask(task.copyWith(evidencePhotoPath: photoPath));
}

@immutable
class KanbanCard {
  const KanbanCard(this.task, this.projectName);

  final Task task;
  final String projectName;
}

@immutable
class KanbanState {
  const KanbanState({
    required this.projects,
    required this.selectedProjectId,
    required this.query,
    required this.columns,
    required this.totalPoints,
    required this.donePoints,
    required this.totalTasks,
  });

  final List<Project> projects;
  final int? selectedProjectId;
  final String query;
  final Map<TaskStatus, List<KanbanCard>> columns;

  /// Points of visible tasks (respects the project filter, not the search).
  final int totalPoints;
  final int donePoints;
  final int totalTasks;

  double get velocity => totalPoints == 0 ? 0 : donePoints / totalPoints;

  int count(TaskStatus status) => columns[status]?.length ?? 0;
}

@immutable
class TaskDraft {
  const TaskDraft({
    this.title = '',
    this.projectId,
    this.description = '',
    this.assignee = '',
    this.priority = TaskPriority.p2,
    this.dueDate,
    this.status = TaskStatus.todo,
    this.storyPoints = Task.defaultStoryPoints,
  });

  final String title;
  final int? projectId;
  final String description;
  final String assignee;
  final TaskPriority priority;
  final DateTime? dueDate;
  final TaskStatus status;
  final int storyPoints;

  bool get isValid => title.trim().isNotEmpty && projectId != null;

  TaskDraft copyWith({
    String? title,
    int? projectId,
    String? description,
    String? assignee,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskStatus? status,
    int? storyPoints,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      storyPoints: storyPoints ?? this.storyPoints,
    );
  }
}

/// Sort key for tasks without due date (max DateTime; bit shifts are 32-bit on web).
const _noDueDate = 8640000000000000;

/// Interactive Kanban board state (mirrors `KanbanViewModel`).
class KanbanController extends DerivedController<KanbanState> {
  KanbanController(this.projectRepository) : super([projectRepository]);

  final ProjectRepository projectRepository;

  int? _selectedProjectId;
  String _query = '';

  /// Last created task: the UI shows the success dialog while not null.
  KanbanCard? createdCard;

  List<Task> get allTasks => projectRepository.tasks;

  void selectProject(int? projectId) {
    _selectedProjectId = projectId;
    invalidate();
  }

  void setQuery(String value) {
    _query = value;
    invalidate();
  }

  @override
  KanbanState build() {
    final projects = projectRepository.projects;
    final names = {for (final p in projects) p.id: p.name};
    final filter = names.containsKey(_selectedProjectId) ? _selectedProjectId : null;
    final scoped = projectRepository.tasks
        .where((t) => names.containsKey(t.projectId))
        .where((t) => filter == null || t.projectId == filter)
        .toList();
    final needle = _query.trim().toLowerCase();
    final cards = [
      for (final t in scoped)
        if (needle.isEmpty ||
            t.title.toLowerCase().contains(needle) ||
            (t.assignee ?? '').toLowerCase().contains(needle) ||
            names[t.projectId]!.toLowerCase().contains(needle))
          KanbanCard(t, names[t.projectId]!),
    ];
    int order(KanbanCard a, KanbanCard b) {
      final byPriority = a.task.priority.index.compareTo(b.task.priority.index);
      if (byPriority != 0) {
        return byPriority;
      }
      final ad = a.task.dueDate?.millisecondsSinceEpoch ?? _noDueDate;
      final bd = b.task.dueDate?.millisecondsSinceEpoch ?? _noDueDate;
      final byDue = ad.compareTo(bd);
      return byDue != 0 ? byDue : a.task.id.compareTo(b.task.id);
    }

    return KanbanState(
      projects: projects,
      selectedProjectId: filter,
      query: _query,
      columns: {
        for (final status in TaskStatus.values)
          status: cards.where((c) => c.task.effectiveStatus == status).toList()..sort(order),
      },
      totalPoints: scoped.fold(0, (a, t) => a + t.storyPoints),
      donePoints: scoped.where((t) => t.isCompleted).fold(0, (a, t) => a + t.storyPoints),
      totalTasks: scoped.length,
    );
  }

  Future<void> moveTask(Task task, TaskStatus target) async {
    if (task.effectiveStatus == target) {
      return;
    }
    await projectRepository.updateTask(task.movedTo(target));
  }

  Future<void> deleteTask(Task task) => projectRepository.deleteTask(task.id);

  Future<void> createTask(TaskDraft draft) async {
    final projectId = draft.projectId;
    if (projectId == null || !draft.isValid) {
      return;
    }
    final task = Task(
      id: 0,
      projectId: projectId,
      title: draft.title.trim(),
      isCompleted: draft.status == TaskStatus.done,
      status: draft.status,
      priority: draft.priority,
      dueDate: draft.dueDate,
      assignee: draft.assignee.trim().isEmpty ? null : draft.assignee.trim(),
      storyPoints: draft.storyPoints,
      description: draft.description.trim().isEmpty ? null : draft.description.trim(),
    );
    final id = await projectRepository.insertTask(task);
    final projectName = state.projects
        .where((p) => p.id == projectId)
        .map((p) => p.name)
        .firstOrNull ?? '';
    createdCard = KanbanCard(task.copyWith(id: id), projectName);
    notifyListeners();
  }

  void dismissCreated() {
    createdCard = null;
    notifyListeners();
  }
}
