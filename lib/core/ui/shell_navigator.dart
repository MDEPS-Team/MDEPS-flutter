import 'package:flutter/material.dart';

enum AppTab { home, projects, analytics, governance, profile }

/// Cross-context navigation contract. Screens of every bounded context
/// navigate through it so they never import each other's UI directly.
abstract class ShellNavigator {
  void goTab(AppTab tab);

  void openProject(int projectId);

  void openProjectRisks(int projectId);

  void openProjectMilestones(int projectId);

  void openKanban({int? projectId});

  void openRoadmap(int projectId);

  void createProject();

  Future<T?> push<T>(Widget page);

  void pop();
}

class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.navigator, required super.child});

  final ShellNavigator navigator;

  static ShellNavigator of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ShellScope>();
    assert(scope != null, 'ShellScope not found');
    return scope!.navigator;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => navigator != oldWidget.navigator;
}
