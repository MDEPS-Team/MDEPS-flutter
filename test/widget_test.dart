import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdeps_flutter/app.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';

abstract final class AppScopeTestAccess {
  static AppServices of(BuildContext context) => AppScope.of(context);
}

abstract final class ShellScopeTestAccess {
  static ShellNavigator of(BuildContext context) => ShellScope.of(context);
}

String es(String key, [List<Object?> args = const []]) => AppStrings.lookup('es', key, args);
String en(String key, [List<Object?> args = const []]) => AppStrings.lookup('en', key, args);

/// Advances time in steps (the shell has an infinite "pulsing dot", so
/// `pumpAndSettle` would never settle).
Future<void> _advance(WidgetTester tester, [int ms = 1500]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _passSplash(WidgetTester tester) async {
  await tester.pumpWidget(const VantagePmoApp());
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await _passSplash(tester);
  await tester.enterText(find.byType(TextField).at(0), 'alex.vance@enterprise.com');
  await tester.enterText(find.byType(TextField).at(1), 'Secret#2025');
  await tester.tap(find.text(es('iam_login_sign_in')));
  await _advance(tester, 2500);
}

void main() {
  setUp(() {
    // Phone-sized viewport like the Figma frames (402×874).
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(402 * 3, 874 * 3);
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('Muestra el splash y luego la pantalla de login', (tester) async {
    await tester.pumpWidget(const VantagePmoApp());

    expect(find.text('Vantage PMO'), findsOneWidget);
    expect(find.text(es('auth_version', [appVersion])), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text(es('auth_welcome_back')), findsOneWidget);
    expect(find.text(es('iam_login_sign_in')), findsOneWidget);
  });

  testWidgets('El registro valida los campos obligatorios', (tester) async {
    await _passSplash(tester);

    final createAccount = find.text(es('auth_create_account'));
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();
    expect(find.text(es('reg_personal_heading')), findsWidgets);

    final cta = find.text(es('reg_cta_to_contact'));
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text(es('reg_error_required')), findsNWidgets(2));
    expect(find.text(es('reg_error_birth_date')), findsOneWidget);
  });

  testWidgets('Login → onboarding → recorre las 5 pestañas', (tester) async {
    await _signIn(tester);

    // Onboarding (3 steps) on first entry.
    expect(find.text(es('onboarding_step_one_title')), findsOneWidget);
    await tester.tap(find.text(es('onboarding_skip')));
    await _advance(tester, 500);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(es('home_hello', ['Alejandro'])), findsOneWidget);

    await tester.tap(find.text(es('nav_tab_projects')));
    await _advance(tester, 800);
    expect(find.text(es('pto_hub_title')), findsOneWidget);
    expect(find.text('ERP Core Implementation'), findsWidgets);

    await tester.tap(find.text(es('nav_tab_analytics')));
    await _advance(tester, 800);
    expect(find.text(es('ass_intelligence_title')), findsOneWidget);

    await tester.tap(find.text(es('nav_tab_governance')));
    await _advance(tester, 800);
    expect(find.text(es('gro_compliance_title').toUpperCase()).hitTestable(), findsOneWidget);

    await tester.tap(find.text(es('nav_tab_profile')));
    await _advance(tester, 800);
    expect(find.text('Alejandro Vance Rivas'), findsOneWidget);
  });

  testWidgets('El perfil cambia el idioma de toda la app a inglés', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text(es('onboarding_skip')));
    await _advance(tester, 500);

    await tester.tap(find.text(es('nav_tab_profile')));
    await _advance(tester, 800);

    final english = find.text(es('profile_language_en'));
    await tester.scrollUntilVisible(english, 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(english);
    await _advance(tester, 800);

    expect(find.text(en('nav_tab_profile')), findsWidgets);
    expect(find.text(en('nav_tab_home')), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('Recorre las pantallas secundarias sin desbordes (dark: $dark)', (tester) async {
      await _signIn(tester);
      await tester.tap(find.text(es('onboarding_skip')));
      await _advance(tester, 500);

      final element = tester.element(find.byType(NavigationBar));
      final services = AppScopeTestAccess.of(element);
      if (dark) {
        await services.profile.setDarkStudio(true);
        await _advance(tester, 500);
      }
      final nav = ShellScopeTestAccess.of(element);

      Future<void> visit(VoidCallback open, String expectedText) async {
        open();
        await _advance(tester, 1200);
        expect(find.text(expectedText), findsWidgets);
        nav.pop();
        await _advance(tester, 800);
      }

      await visit(() => nav.openRoadmap(2), es('rm_title'));
      await visit(() => nav.openProjectRisks(2), es('gro_risks_title'));
      await visit(() => nav.openProjectMilestones(2), es('gro_milestones_title'));
      await visit(nav.createProject, es('pto_create_headline'));
      await visit(() => nav.openKanban(projectId: 2), es('kb_title'));

      // Kanban "create task" sheet.
      nav.openKanban();
      await _advance(tester, 1200);
      await tester.tap(find.text(es('kb_add_task')));
      await _advance(tester, 1000);
      expect(find.text(es('kb_field_title').toUpperCase()), findsOneWidget);
    });
  }

  testWidgets('Perfil: foto, editar cuenta y cerrar sesión con confirmación', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text(es('onboarding_skip')));
    await _advance(tester, 500);
    await tester.tap(find.text(es('nav_tab_profile')));
    await _advance(tester, 800);

    // Update profile photo → preset avatar with initials.
    await tester.tap(find.byTooltip(es('iam_profile_change_avatar')));
    await _advance(tester, 800);
    expect(find.text(es('pm_avatar_sheet_title')), findsOneWidget);
    await tester.tap(find.text(es('pm_avatar_apply')));
    await _advance(tester, 800);
    expect(find.text('AV'), findsOneWidget);
    await _advance(tester, 5000); // let the "photo updated" snackbar go away

    // Edit account & security sheet.
    await tester.ensureVisible(find.text(es('iam_profile_edit')));
    await _advance(tester, 400);
    await tester.tap(find.text(es('iam_profile_edit')));
    await _advance(tester, 800);
    expect(find.text(es('iam_security_sheet_title')), findsOneWidget);
    await tester.tap(find.byTooltip(es('iam_a11y_security_close')));
    await _advance(tester, 800);

    // Logout → confirm → success → back to login.
    final logout = find.text(es('iam_profile_logout'));
    await tester.scrollUntilVisible(logout, 300, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.tap(logout);
    await _advance(tester, 600);
    expect(find.text(es('pm_logout_confirm_title')), findsOneWidget);
    await tester.tap(find.text(es('pm_logout_confirm_action')));
    await _advance(tester, 3000);
    expect(find.text(es('auth_welcome_back')), findsOneWidget);
  });

  testWidgets('Abre el detalle de un proyecto y el kanban desde Proyectos', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text(es('onboarding_skip')));
    await _advance(tester, 500);

    await tester.tap(find.text(es('nav_tab_projects')));
    await _advance(tester, 800);
    final project = find.text('Cloud Migration Wave 2').hitTestable();
    await tester.scrollUntilVisible(project, 300, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.tap(project.first);
    await _advance(tester, 1200);

    expect(find.text(es('pto_tasks_section_title')), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip(es('kb_title')));
    await _advance(tester, 1200);
    expect(find.text(es('kb_burndown')), findsOneWidget);
  });
}
