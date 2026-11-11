import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/pto/domain/pto_models.dart';

/// In-memory replacement of the Room `PtoDatabase`, seeded with a demo
/// portfolio so every screen has content on first launch.
class InMemoryProjectRepository extends ChangeNotifier implements ProjectRepository {
  InMemoryProjectRepository({bool seed = true}) {
    if (seed) {
      _seed();
    }
  }

  final List<Project> _projects = [];
  final List<Task> _tasks = [];
  int _nextProjectId = 1;
  int _nextTaskId = 1;

  @override
  List<Project> get projects => List.unmodifiable(_projects);

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);

  @override
  List<Task> tasksOf(int projectId) => _tasks.where((t) => t.projectId == projectId).toList();

  @override
  int get activeProjectCount => _projects.where((p) => p.status != ProjectStatus.completed).length;

  @override
  int get pendingTaskCount {
    final ids = _projects.map((p) => p.id).toSet();
    return _tasks.where((t) => !t.isCompleted && ids.contains(t.projectId)).length;
  }

  @override
  Future<int> insertProject(Project project) async {
    final id = _nextProjectId++;
    _projects.insert(
      0,
      Project(id: id, name: project.name, description: project.description, status: project.status),
    );
    notifyListeners();
    return id;
  }

  @override
  Future<void> updateProject(Project project) async {
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i >= 0) {
      _projects[i] = project;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteProject(int projectId) async {
    _tasks.removeWhere((t) => t.projectId == projectId);
    _projects.removeWhere((p) => p.id == projectId);
    notifyListeners();
  }

  @override
  Future<int> insertTask(Task task) async {
    final id = _nextTaskId++;
    _tasks.add(task.copyWith(id: id));
    notifyListeners();
    return id;
  }

  @override
  Future<void> updateTask(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      // Keep status coherent with the completion flag (as the Room mapper does).
      _tasks[i] = task.copyWith(status: task.effectiveStatus);
      notifyListeners();
    }
  }

  @override
  Future<void> deleteTask(int taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    DateTime inDays(int d) => DateTime(now.year, now.month, now.day).add(Duration(days: d));

    Project p(String name, String brief, ProjectStatus status) {
      final project = Project(id: _nextProjectId++, name: name, description: brief, status: status);
      _projects.add(project);
      return project;
    }

    void t(
      Project project,
      String title, {
      TaskStatus status = TaskStatus.todo,
      TaskPriority priority = TaskPriority.p2,
      int? due,
      String? assignee,
      int points = 3,
    }) {
      _tasks.add(
        Task(
          id: _nextTaskId++,
          projectId: project.id,
          title: title,
          isCompleted: status == TaskStatus.done,
          status: status,
          priority: priority,
          dueDate: due == null ? null : inDays(due),
          assignee: assignee,
          storyPoints: points,
        ),
      );
    }

    final erp = p(
      'ERP Core Implementation',
      'Unified finance, procurement and HR modules on a single ERP core with '
          'real-time ledger reconciliation.\n[risk=moderate;soc2=on;domains=backend,api]',
      ProjectStatus.inProgress,
    );
    final zeroTrust = p(
      'Zero Trust Infrastructure',
      'Network segmentation, continuous identity verification and policy-as-code '
          'for every corporate workload.\n[risk=high;soc2=on;domains=api,backend,mobile]',
      ProjectStatus.atRisk,
    );
    final cloud = p(
      'Cloud Migration Wave 2',
      'Lift-and-optimize of 42 legacy services to the multi-region landing zone '
          'with FinOps guardrails.\n[risk=low;soc2=on;domains=data]',
      ProjectStatus.inProgress,
    );
    final dataLake = p(
      'Zero Trust Data Lake & Audit Vault',
      'Unified distributed audit deployment with homomorphic encryption for banking '
          'transaction telemetry and GDPR / DORA data sovereignty.\n'
          '[risk=moderate;soc2=on;domains=backend,api]',
      ProjectStatus.planning,
    );
    final portal = p(
      'Customer Portal Revamp',
      'Self-service portal with SSO, accessibility AA and a redesigned billing journey.',
      ProjectStatus.completed,
    );

    t(erp, 'provision:kickoff', status: TaskStatus.done, priority: TaskPriority.p1, due: -20, assignee: 'Alejandro Vance', points: 2);
    t(erp, 'provision:raci', status: TaskStatus.done, due: -14, assignee: 'M. Ramos', points: 2);
    t(erp, 'General ledger data migration', status: TaskStatus.inProgress, priority: TaskPriority.p0, due: 3, assignee: 'K. Leung', points: 8);
    t(erp, 'Procurement approval workflows', status: TaskStatus.review, priority: TaskPriority.p1, due: 6, assignee: 'T. Alvarez', points: 5);
    t(erp, 'Payroll integration test plan', priority: TaskPriority.p2, due: 12, assignee: 'L. Pérez', points: 3);
    t(erp, 'Finance UAT sign-off', priority: TaskPriority.p1, due: 21, assignee: 'Alejandro Vance', points: 3);

    t(zeroTrust, 'provision:kickoff', status: TaskStatus.done, priority: TaskPriority.p1, due: -30, assignee: 'K. Leung', points: 2);
    t(zeroTrust, 'Micro-segmentation of core VLANs', status: TaskStatus.inProgress, priority: TaskPriority.p0, due: -2, assignee: 'D. Novak', points: 8);
    t(zeroTrust, 'Network validation bottleneck review', priority: TaskPriority.p0, due: 2, assignee: 'T. Alvarez', points: 5);
    t(zeroTrust, 'Device posture policy rollout', status: TaskStatus.review, priority: TaskPriority.p1, due: 5, assignee: 'S. Kim', points: 5);
    t(zeroTrust, 'Privileged access vault onboarding', priority: TaskPriority.p1, due: 9, assignee: 'K. Leung', points: 5);
    t(zeroTrust, 'Pen-test remediation backlog', priority: TaskPriority.p2, due: 15, assignee: 'L. Pérez', points: 3);

    t(cloud, 'provision:kickoff', status: TaskStatus.done, due: -40, assignee: 'D. Novak', points: 2);
    t(cloud, 'Landing zone hardening', status: TaskStatus.done, priority: TaskPriority.p1, due: -18, assignee: 'D. Novak', points: 5);
    t(cloud, 'Migrate billing services', status: TaskStatus.done, priority: TaskPriority.p1, due: -7, assignee: 'K. Leung', points: 8);
    t(cloud, 'Migrate reporting services', status: TaskStatus.inProgress, due: 4, assignee: 'S. Kim', points: 5);
    t(cloud, 'FinOps cost dashboards', status: TaskStatus.review, priority: TaskPriority.p3, due: 8, assignee: 'M. Ramos', points: 2);

    t(dataLake, 'provision:kickoff', priority: TaskPriority.p1, due: 5, assignee: 'Alejandro Vance', points: 2);
    t(dataLake, 'provision:raci', due: 9, assignee: 'M. Ramos', points: 2);
    t(dataLake, 'Homomorphic encryption spike', priority: TaskPriority.p2, due: 18, assignee: 'S. Kim', points: 5);

    t(portal, 'SSO & accessibility audit', status: TaskStatus.done, due: -60, assignee: 'L. Pérez', points: 3);
    t(portal, 'Billing journey redesign', status: TaskStatus.done, due: -45, assignee: 'T. Alvarez', points: 5);
    t(portal, 'Go-live hypercare', status: TaskStatus.done, due: -30, assignee: 'Alejandro Vance', points: 3);
  }
}

