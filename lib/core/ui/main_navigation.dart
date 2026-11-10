import 'package:flutter/material.dart';
import 'package:mdeps_flutter/ass/ui/screens/analytics_screen.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/gro/ui/screens/governance_hub_screen.dart';
import 'package:mdeps_flutter/gro/ui/screens/milestone_timeline_screen.dart';
import 'package:mdeps_flutter/gro/ui/screens/risk_matrix_screen.dart';
import 'package:mdeps_flutter/pm/ui/screens/profile_screen.dart';
import 'package:mdeps_flutter/pto/ui/screens/create_initiative_screen.dart';
import 'package:mdeps_flutter/pto/ui/screens/home_screen.dart';
import 'package:mdeps_flutter/pto/ui/screens/kanban_screen.dart';
import 'package:mdeps_flutter/pto/ui/screens/project_detail_screen.dart';
import 'package:mdeps_flutter/pto/ui/screens/project_list_screen.dart';
import 'package:mdeps_flutter/pto/ui/screens/roadmap_screen.dart';

/// Authenticated shell: the five bounded-context tabs plus a nested
/// navigator for full-screen flows (project hub, risks, timeline, kanban,
/// roadmap, create initiative), which hide the bottom bar.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> implements ShellNavigator {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _tab = ValueNotifier(AppTab.home);

  NavigatorState get _nav => _navigatorKey.currentState!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ───────────── ShellNavigator ─────────────

  @override
  void goTab(AppTab tab) {
    _nav.popUntil((route) => route.isFirst);
    _tab.value = tab;
  }

  @override
  Future<T?> push<T>(Widget page) => _nav.push<T>(MaterialPageRoute(builder: (_) => page));

  @override
  void pop() => _nav.maybePop();

  @override
  void openProject(int projectId) => push<void>(ProjectDetailScreen(projectId: projectId));

  @override
  void openProjectRisks(int projectId) => push<void>(RiskMatrixScreen(projectId: projectId));

  @override
  void openProjectMilestones(int projectId) => push<void>(MilestoneTimelineScreen(projectId: projectId));

  @override
  void openKanban({int? projectId}) => push<void>(KanbanScreen(initialProjectId: projectId));

  @override
  void openRoadmap(int projectId) => push<void>(RoadmapScreen(projectId: projectId));

  @override
  void createProject() {
    push<void>(
      CreateInitiativeScreen(
        onClose: pop,
        onCreated: (id) {
          _nav.pop();
          if (id != null) {
            openProject(id);
          }
        },
      ),
    );
  }

  // ───────────── Onboarding ─────────────

  Future<void> _maybeShowOnboarding() async {
    final settings = AppScope.of(context).settings;
    if (settings.onboardingCompleted || !mounted) {
      return;
    }
    settings.onboardingCompleted = true;
    await showDialog<void>(context: _navigatorKey.currentContext!, builder: (_) => const _OnboardingDialog());
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      navigator: this,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _nav.maybePop(),
        child: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => _TabShell(tab: _tab, onLogout: widget.onLogout),
          ),
        ),
      ),
    );
  }
}

class _TabShell extends StatelessWidget {
  const _TabShell({required this.tab, required this.onLogout});

  final ValueNotifier<AppTab> tab;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: tab,
      builder: (context, current, _) => Scaffold(
        body: IndexedStack(
          index: current.index,
          children: [
            const HomeScreen(),
            const ProjectListScreen(),
            const AnalyticsScreen(),
            const GovernanceHubScreen(),
            ProfileScreen(onLogout: onLogout),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (i) => tab.value = AppTab.values[i],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home), label: context.tr('nav_tab_home')),
            NavigationDestination(icon: const Icon(Icons.list), label: context.tr('nav_tab_projects')),
            NavigationDestination(icon: const Icon(Icons.info), label: context.tr('nav_tab_analytics')),
            NavigationDestination(icon: const Icon(Icons.check_circle), label: context.tr('nav_tab_governance')),
            NavigationDestination(icon: const Icon(Icons.person), label: context.tr('nav_tab_profile')),
          ],
        ),
      ),
    );
  }
}

/// Three-step first-run onboarding.
class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    const titles = ['onboarding_step_one_title', 'onboarding_step_two_title', 'onboarding_step_three_title'];
    const bodies = ['onboarding_step_one_body', 'onboarding_step_two_body', 'onboarding_step_three_body'];
    final last = _step >= 2;
    return AlertDialog(
      title: Text(context.tr(titles[_step]), style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(context.tr(bodies[_step])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('onboarding_skip'))),
        FilledButton(
          onPressed: last ? () => Navigator.pop(context) : () => setState(() => _step++),
          child: Text(context.tr(last ? 'onboarding_finish' : 'onboarding_next')),
        ),
      ],
    );
  }
}
