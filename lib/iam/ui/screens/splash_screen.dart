import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_brand.dart';

/// Brand splash (~1.3 s): the mark springs in from 0.88, the name rises 12dp
/// with a fade, then the tagline appears. A soft radial halo breathes behind.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.versionName, required this.onFinished});

  final String versionName;
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mark = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _title = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _tagline = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _run();
  }

  Future<void> _run() async {
    if (VxMotion.reduced(context)) {
      _mark.value = 1;
      _title.value = 1;
      _tagline.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    } else {
      _halo.repeat(reverse: true);
      _mark.forward();
      await Future<void>.delayed(const Duration(milliseconds: 160));
      _title.forward();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      _tagline.forward();
      await Future<void>.delayed(const Duration(milliseconds: 950));
    }
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _mark.dispose();
    _title.dispose();
    _tagline.dispose();
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final markCurve = CurvedAnimation(parent: _mark, curve: Curves.elasticOut);
    final titleCurve = CurvedAnimation(parent: _title, curve: VxMotion.easeOut);
    final taglineCurve = CurvedAnimation(parent: _tagline, curve: VxMotion.easeOut);

    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mark, _title, _tagline, _halo]),
        builder: (context, _) {
          final markValue = markCurve.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _mark.value,
                child: Transform.scale(
                  scale: 0.92 + 0.16 * Curves.linear.transform(_halo.value),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4A5568).withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _mark.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.88 + 0.12 * markValue,
                      child: const VxBrandMark(size: 72),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: titleCurve.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - titleCurve.value) * 12),
                      child: Text(
                        context.tr('app_name'),
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Opacity(
                      opacity: taglineCurve.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - taglineCurve.value) * 8),
                        child: Text(
                          context.tr('auth_tagline').toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.4,
                            color: p.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 32 + MediaQuery.paddingOf(context).bottom,
                child: Opacity(
                  opacity: _tagline.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('auth_version', [widget.versionName]),
                          style: TextStyle(
                            fontSize: 12,
                            color: p.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
