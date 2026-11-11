import 'package:flutter/material.dart';

/// App-wide user preferences: language and the "Dark Studio" theme.
class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('es');
  bool _darkStudio = false;

  /// First-run onboarding (kept in memory: shown once per app launch).
  bool onboardingCompleted = false;

  Locale get locale => _locale;
  bool get darkStudio => _darkStudio;

  void setLocale(Locale locale) {
    if (locale == _locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
  }

  void setDarkStudio(bool enabled) {
    if (enabled == _darkStudio) {
      return;
    }
    _darkStudio = enabled;
    notifyListeners();
  }
}
