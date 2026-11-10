import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/app_theme.dart';
import 'package:mdeps_flutter/core/ui/main_navigation.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/iam/application/iam_controllers.dart';
import 'package:mdeps_flutter/iam/ui/screens/login_screen.dart';
import 'package:mdeps_flutter/iam/ui/screens/password_recovery_screen.dart';
import 'package:mdeps_flutter/iam/ui/screens/register_flow_screen.dart';
import 'package:mdeps_flutter/iam/ui/screens/splash_screen.dart';

const appVersion = '1.0.0';

class VantagePmoApp extends StatefulWidget {
  const VantagePmoApp({super.key});

  @override
  State<VantagePmoApp> createState() => _VantagePmoAppState();
}

class _VantagePmoAppState extends State<VantagePmoApp> {
  final _services = AppServices();

  @override
  void dispose() {
    _services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: ListenableBuilder(
        listenable: _services.settings,
        builder: (context, _) => MaterialApp(
          title: 'Vantage PMO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _services.settings.darkStudio ? ThemeMode.dark : ThemeMode.light,
          locale: _services.settings.locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

enum _AuthRoute { splash, login, register, recovery }

/// Session gate: splash → sign in / register / recover → main shell.
/// The session is not remembered across cold starts (always asks for access).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  _AuthRoute _route = _AuthRoute.splash;
  bool _unlocked = false;
  RegistrationController? _registration;
  PasswordRecoveryController? _recovery;

  @override
  void dispose() {
    _registration?.dispose();
    _recovery?.dispose();
    super.dispose();
  }

  void _go(_AuthRoute route) {
    setState(() {
      // Each entry into a flow starts with a fresh controller.
      if (route == _AuthRoute.register) {
        _registration?.dispose();
        _registration = RegistrationController(AppScope.of(context).authRepository);
      }
      if (route == _AuthRoute.recovery) {
        _recovery?.dispose();
        _recovery = PasswordRecoveryController(AppScope.of(context).authRepository);
      }
      _route = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final iam = services.iam;

    if (_unlocked) {
      return MainNavigation(
        onLogout: () async {
          await iam.endActiveSession();
          setState(() {
            _unlocked = false;
            _route = _AuthRoute.login;
          });
        },
      );
    }

    final Widget page = switch (_route) {
      _AuthRoute.splash => SplashScreen(
          versionName: appVersion,
          onFinished: () => _go(_AuthRoute.login),
        ),
      _AuthRoute.login => LoginScreen(
          controller: iam,
          onLoginSuccess: () => setState(() => _unlocked = true),
          onCreateAccount: () => _go(_AuthRoute.register),
          onForgotPassword: () => _go(_AuthRoute.recovery),
        ),
      _AuthRoute.register => RegisterFlowScreen(
          controller: _registration!,
          onExit: () => _go(_AuthRoute.login),
          onFinished: () => setState(() => _unlocked = true),
        ),
      _AuthRoute.recovery => ListenableBuilder(
          listenable: iam,
          builder: (context, _) => PasswordRecoveryScreen(
            controller: _recovery!,
            entering: iam.isLoading,
            onExit: () => _go(_AuthRoute.login),
            onEnterApp: (email, password) async {
              await iam.signIn(email, password);
              if (mounted && iam.isAuthenticated) {
                setState(() => _unlocked = true);
              }
            },
          ),
        ),
    };

    return AnimatedSwitcher(
      duration: VxMotion.standard,
      reverseDuration: const Duration(milliseconds: 160),
      switchInCurve: VxMotion.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_route), child: page),
    );
  }
}
