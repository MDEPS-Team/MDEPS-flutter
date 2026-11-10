import 'package:flutter/material.dart';

/// Motion tokens shared across the app (mirrors the Compose `VxMotion`).
abstract final class VxMotion {
  /// Strong ease-out: immediate response for entrances and feedback.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out: movement of elements already on screen.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  static const press = Duration(milliseconds: 140);
  static const fast = Duration(milliseconds: 200);
  static const standard = Duration(milliseconds: 280);
  static const staggerMs = 45;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Scales the child to [pressedScale] while pressed, without stealing taps.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.enabled && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: VxMotion.press,
        curve: VxMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Staggered entrance: fade + short 12dp rise with ease-out. Plays once.
class StaggeredEnter extends StatefulWidget {
  const StaggeredEnter({
    super.key,
    required this.index,
    required this.child,
    this.baseDelayMs = 0,
  });

  final int index;
  final int baseDelayMs;
  final Widget child;

  @override
  State<StaggeredEnter> createState() => _StaggeredEnterState();
}

class _StaggeredEnterState extends State<StaggeredEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: VxMotion.standard + const Duration(milliseconds: 60),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: VxMotion.easeOut);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (VxMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    final delay = widget.baseDelayMs + widget.index * VxMotion.staggerMs;
    Future<void>.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * 12),
          child: child,
        ),
      ),
    );
  }
}

/// Fade + slight scale-in page transition used by the auth flow.
Route<T> vxFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: VxMotion.standard,
    reverseTransitionDuration: VxMotion.fast,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: VxMotion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
