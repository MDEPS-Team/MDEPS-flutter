import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';

/// Flat card with a soft border (avoids shadow artifacts on tinted backgrounds).
class VxCard extends StatelessWidget {
  const VxCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
    this.borderColor,
    this.radius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? p.line),
    );
    final content = padding == null ? child : Padding(padding: padding!, child: child);
    return Material(
      color: color ?? p.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.size = 11,
    this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: fg, fontSize: size, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(
    this.initials, {
    super.key,
    this.size = 36,
    this.bg,
    this.fg = Vx.blue,
  });

  final String initials;
  final double size;
  final Color? bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg ?? context.vx.blueSoft, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.36),
      ),
    );
  }
}

/// Uppercase micro-label used for section headings.
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? context.vx.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class VxProgress extends StatelessWidget {
  const VxProgress({
    super.key,
    required this.progress,
    required this.color,
    this.track,
    this.height = 8,
  });

  final double progress;
  final Color color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track ?? context.vx.chip)),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square blue profile shortcut shown in top bars.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, required this.onTap, this.tooltip = 'Profile'});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Vx.blue,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded square with an icon (used as section/brand badges).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize = 20,
    this.bg = Vx.blue,
    this.fg = Colors.white,
    this.radius = 10,
    this.circle = false,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color bg;
  final Color fg;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: fg, size: iconSize),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({super.key, required this.color, this.size = 8, this.square = false});

  final Color color;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(2) : null,
      ),
    );
  }
}

/// Top bar matching the Compose `VxTopBar` (flat, page background).
class VxTopBar extends StatelessWidget implements PreferredSizeWidget {
  const VxTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
  });

  final Widget title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.vx.bg,
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 16 : 0,
      title: title,
      actions: actions,
    );
  }
}

/// "VANTAGE / Title" top-bar heading with brand badge.
class VxBrandTitle extends StatelessWidget {
  const VxBrandTitle({super.key, required this.title, this.icon = Icons.info});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Row(
      children: [
        IconBadge(icon: icon),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VANTAGE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: p.muted,
                letterSpacing: 1,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
            ),
          ],
        ),
      ],
    );
  }
}

void showVxSnack(BuildContext context, String message, {String? action, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        action: action == null
            ? null
            : SnackBarAction(label: action, onPressed: onAction ?? () {}),
      ),
    );
}
