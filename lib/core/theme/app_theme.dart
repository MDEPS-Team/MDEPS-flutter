import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, VxPalette.light);

  static ThemeData dark() => _build(Brightness.dark, VxPalette.dark);

  static ThemeData _build(Brightness brightness, VxPalette p) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? const Color(0xFF6BA3FF) : Vx.blue,
      onPrimary: isDark ? const Color(0xFF0A1628) : Colors.white,
      primaryContainer: p.blueSoft,
      onPrimaryContainer: isDark ? const Color(0xFFD8E6FF) : Vx.blue,
      secondary: p.muted,
      onSecondary: Colors.white,
      secondaryContainer: p.blueSoft,
      onSecondaryContainer: isDark ? const Color(0xFFD8E6FF) : Vx.blue,
      tertiary: isDark ? const Color(0xFF5CD9A8) : Vx.green,
      onTertiary: Colors.white,
      error: isDark ? const Color(0xFFFFB4AB) : Vx.red,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.bg,
      surfaceContainer: p.chip,
      surfaceContainerHigh: p.chip,
      surfaceContainerHighest: p.line,
      outline: p.gray,
      outlineVariant: p.line,
      inverseSurface: p.ink,
      onInverseSurface: p.surface,
      inversePrimary: isDark ? Vx.blue : const Color(0xFF6BA3FF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.blueSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected) ? Vx.blue : p.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? Vx.blue : p.muted,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Vx.blue : null,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: p.line, space: 1),
    );
  }
}
