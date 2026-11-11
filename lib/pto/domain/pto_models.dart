import 'package:flutter/foundation.dart';

enum ProjectStatus { planning, inProgress, atRisk, completed }

@immutable
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
  });

  final int id;
  final String name;
  final String description;
  final ProjectStatus status;

  Project copyWith({String? name, String? description, ProjectStatus? status}) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}

/// Kanban columns. [done] is equivalent to `Task.isCompleted == true`.
enum TaskStatus {
  todo,
  inProgress,
  review,
  done;

  TaskStatus? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// P0 = critical … P3 = low.
enum TaskPriority { p0, p1, p2, p3 }

@immutable
class Task {
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.isCompleted,
    this.evidencePhotoPath,
    TaskStatus? status,
    this.priority = TaskPriority.p2,
    this.dueDate,
    this.assignee,
    this.storyPoints = defaultStoryPoints,
    this.description,
  }) : status = status ?? (isCompleted ? TaskStatus.done : TaskStatus.todo);

  static const defaultStoryPoints = 3;

  final int id;
  final int projectId;
  final String title;
  final bool isCompleted;
  final String? evidencePhotoPath;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? assignee;
  final int storyPoints;
  final String? description;

  /// Status consistent with [isCompleted] (the rest of the app only knows the boolean).
  TaskStatus get effectiveStatus {
    if (isCompleted) {
      return TaskStatus.done;
    }
    return status == TaskStatus.done ? TaskStatus.todo : status;
  }

  Task movedTo(TaskStatus target) =>
      copyWith(status: target, isCompleted: target == TaskStatus.done);

  Task copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    String? evidencePhotoPath,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? assignee,
    int? storyPoints,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      evidencePhotoPath: evidencePhotoPath ?? this.evidencePhotoPath,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignee: assignee ?? this.assignee,
      storyPoints: storyPoints ?? this.storyPoints,
      description: description ?? this.description,
    );
  }
}

final _metadataBracketLine = RegExp(r'^\[[^\]]*]\s*$');
final _domainsRegex = RegExp('domains=([a-z_,]+)', caseSensitive: false);

/// User-facing brief; removes the `[risk=…;soc2=on]` line added on provisioning.
String stripInitiativeMetadata(String description) => description
    .split('\n')
    .where((line) => line.trim().isNotEmpty && !_metadataBracketLine.hasMatch(line.trim()))
    .join('\n')
    .trim();

Set<String> parseInitiativeDomains(String description) {
  final match = _domainsRegex.firstMatch(description);
  if (match == null) {
    return {};
  }
  return match
      .group(1)!
      .split(',')
      .map((d) => d.trim().toLowerCase())
      .where((d) => d.isNotEmpty)
      .toSet();
}

@immutable
class ProjectWithProgress {
  const ProjectWithProgress({
    required this.project,
    required this.progress,
    required this.pendingTaskCount,
    required this.totalTaskCount,
  });

  final Project project;
  final double progress;
  final int pendingTaskCount;
  final int totalTaskCount;
}

/// Port to project & task persistence. Implementations notify listeners on change.
abstract class ProjectRepository implements Listenable {
  List<Project> get projects;

  List<Task> get tasks;

  List<Task> tasksOf(int projectId);

  int get activeProjectCount;

  int get pendingTaskCount;

  Future<int> insertProject(Project project);

  Future<void> updateProject(Project project);

  Future<void> deleteProject(int projectId);

  Future<int> insertTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> deleteTask(int taskId);
}

List<ProjectWithProgress> mapPortfolio(List<Project> projects, List<Task> tasks) {
  final byProject = <int, List<Task>>{};
  for (final t in tasks) {
    byProject.putIfAbsent(t.projectId, () => []).add(t);
  }
  return [
    for (final project in projects)
      () {
        final list = byProject[project.id] ?? const <Task>[];
        final completed = list.where((t) => t.isCompleted).length;
        return ProjectWithProgress(
          project: project,
          progress: list.isEmpty ? 0 : completed / list.length,
          pendingTaskCount: list.where((t) => !t.isCompleted).length,
          totalTaskCount: list.length,
        );
      }(),
  ];
}
