import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/iam/domain/iam_models.dart';

/// Auth flow header: back button + "VANTAGE PMO" eyebrow + title.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: context.tr('auth_a11y_back'),
              icon: Icon(Icons.arrow_back, color: p.ink),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('auth_eyebrow'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: p.muted,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, upcoming }

/// Step indicator: connected circles; done steps show a check and the
/// connector fills towards the current step.
class AuthStepper extends StatelessWidget {
  const AuthStepper({super.key, required this.labels, required this.currentIndex});

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Semantics(
      label: context.tr('auth_a11y_step', [currentIndex + 1, labels.length]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ConnectorHalf(
                                visible: i > 0,
                                filled: i >= 1 && i <= currentIndex,
                                delay: i == currentIndex,
                              ),
                            ),
                            Expanded(
                              child: _ConnectorHalf(
                                visible: i < labels.length - 1,
                                filled: i < currentIndex,
                              ),
                            ),
                          ],
                        ),
                        _StepDot(
                          number: i + 1,
                          state: i < currentIndex
                              ? _StepState.done
                              : i == currentIndex
                                  ? _StepState.current
                                  : _StepState.upcoming,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                        color: i > currentIndex ? p.muted : p.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectorHalf extends StatelessWidget {
  const _ConnectorHalf({required this.visible, required this.filled, this.delay = false});

  final bool visible;
  final bool filled;
  final bool delay;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final p = context.vx;
    return Container(
      height: 2,
      color: p.line,
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: filled ? 1 : 0),
        duration: VxMotion.standard + (delay ? VxMotion.fast : Duration.zero),
        curve: delay ? const Interval(0.4, 1, curve: VxMotion.easeOut) : VxMotion.easeInOut,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value,
          child: Container(color: p.ink),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.state});

  final int number;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return AnimatedScale(
      scale: state == _StepState.current ? 1.08 : 1,
      duration: VxMotion.standard,
      curve: VxMotion.easeOut,
      child: Container(
        width: 30,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
        child: AnimatedContainer(
          duration: VxMotion.standard,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state == _StepState.upcoming ? p.chip : p.ink,
            shape: BoxShape.circle,
            border: state == _StepState.current
                ? Border.all(color: p.surface.withValues(alpha: 0.35), width: 2)
                : null,
          ),
          child: state == _StepState.done
              ? Icon(Icons.check, size: 14, color: p.surface)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: state == _StepState.current ? p.surface : p.muted,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Password security meter with 3 animated segments.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final (level, color, labelKey) = switch (strength) {
      PasswordStrength.none => (0, p.line, 'auth_strength_none'),
      PasswordStrength.weak => (1, Vx.red, 'auth_strength_weak'),
      PasswordStrength.medium => (2, const Color(0xFFD08A0B), 'auth_strength_medium'),
      PasswordStrength.strong => (3, Vx.green, 'auth_strength_strong'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('auth_strength_label', [context.tr(labelKey)]),
          style: TextStyle(fontSize: 11, color: p.muted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.chip,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i < level ? 1 : 0),
                    duration: VxMotion.fast + const Duration(milliseconds: 40),
                    curve: VxMotion.easeOut,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      child: AnimatedContainer(
                        duration: VxMotion.fast,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// "STEP X OF Y • TOPIC" eyebrow + title + description inside each step.
class StepIntro extends StatelessWidget {
  const StepIntro({super.key, required this.eyebrow, required this.title, this.description});

  final String eyebrow;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: p.muted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.ink),
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              description!,
              style: TextStyle(fontSize: 14, height: 1.43, color: p.muted),
            ),
          ),
      ],
    );
  }
}

/// Bordered tile used for SSO providers and similar square actions.
class AuthTile extends StatelessWidget {
  const AuthTile({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.color,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.width,
    this.height,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressScale(
        enabled: enabled,
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: color ?? p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: p.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: Padding(padding: padding, child: Center(child: child)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Underlined inline text action ("Forgot password?", "Create account").
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.text, required this.onTap, this.bold = false});

  final String text;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: p.ink,
            decoration: TextDecoration.underline,
            decorationColor: p.ink,
          ),
        ),
      ),
    );
  }
}
