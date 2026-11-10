import 'package:flutter/material.dart';

/// Design tokens extracted from the Vantage PMO mockups (Figma "PMO").
///
/// Brand accents are constant across themes; neutrals live in [VxPalette]
/// so they can switch between light and the "Dark Studio" theme.
abstract final class Vx {
  static const blue = Color(0xFF0B57D0);
  static const green = Color(0xFF0B7A4B);
  static const red = Color(0xFFB3261E);
  static const teal = Color(0xFF4FD1B0);
  static const amber = Color(0xFFB26A00);
  static const brandNavy = Color(0xFF002896);
}

@immutable
class VxPalette extends ThemeExtension<VxPalette> {
  const VxPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.chip,
    required this.blueSoft,
    required this.greenSoft,
    required this.redSoft,
    required this.gray,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color chip;
  final Color blueSoft;
  final Color greenSoft;
  final Color redSoft;
  final Color gray;

  static const light = VxPalette(
    bg: Color(0xFFF3F5F9),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1F2B),
    muted: Color(0xFF677084),
    line: Color(0xFFE4E8EF),
    chip: Color(0xFFEDF0F5),
    blueSoft: Color(0xFFE3ECFC),
    greenSoft: Color(0xFFDDF3E8),
    redSoft: Color(0xFFFBE4E2),
    gray: Color(0xFFC4CBD8),
  );

  static const dark = VxPalette(
    bg: Color(0xFF0E1118),
    surface: Color(0xFF171C26),
    ink: Color(0xFFE8ECF4),
    muted: Color(0xFF9DA8BC),
    line: Color(0xFF2E3646),
    chip: Color(0xFF222833),
    blueSoft: Color(0xFF1A3055),
    greenSoft: Color(0xFF153328),
    redSoft: Color(0xFF3D2220),
    gray: Color(0xFF4A5364),
  );

  @override
  VxPalette copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? chip,
    Color? blueSoft,
    Color? greenSoft,
    Color? redSoft,
    Color? gray,
  }) {
    return VxPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      chip: chip ?? this.chip,
      blueSoft: blueSoft ?? this.blueSoft,
      greenSoft: greenSoft ?? this.greenSoft,
      redSoft: redSoft ?? this.redSoft,
      gray: gray ?? this.gray,
    );
  }

  @override
  VxPalette lerp(VxPalette? other, double t) {
    if (other == null) {
      return this;
    }
    return VxPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      redSoft: Color.lerp(redSoft, other.redSoft, t)!,
      gray: Color.lerp(gray, other.gray, t)!,
    );
  }
}

extension VxPaletteContext on BuildContext {
  VxPalette get vx => Theme.of(this).extension<VxPalette>() ?? VxPalette.light;
}
