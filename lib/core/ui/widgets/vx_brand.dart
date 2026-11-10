import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';

/// Vantage PMO brand mark: white "V" on the navy rounded square
/// (ported 1:1 from `res/drawable/ic_brand_mark.xml`, viewport 290×290).
class VxBrandMark extends StatelessWidget {
  const VxBrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrandMarkPainter()),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 290;
    canvas.scale(s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 290, 290), const Radius.circular(36)),
      Paint()..color = Vx.brandNavy,
    );
    final v = Path()
      ..moveTo(80, 78.5)
      ..lineTo(111.2, 78.5)
      ..lineTo(145, 180)
      ..lineTo(178.8, 78.5)
      ..lineTo(210, 78.5)
      ..lineTo(162.1, 211)
      ..lineTo(127.9, 211)
      ..close();
    canvas.drawPath(v, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One-shot celebration: the ring draws, then the check traces its path.
/// The container springs in from 0.85 (never from 0).
class AnimatedSuccessMark extends StatefulWidget {
  const AnimatedSuccessMark({
    super.key,
    this.size = 96,
    this.colors = const [Color(0xFF2F7BF5), Color(0xFF0B47B0)],
  });

  final double size;
  final List<Color> colors;

  @override
  State<AnimatedSuccessMark> createState() => _AnimatedSuccessMarkState();
}

class _AnimatedSuccessMarkState extends State<AnimatedSuccessMark>
    with TickerProviderStateMixin {
  late final AnimationController _container = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (VxMotion.reduced(context)) {
      _container.value = 1;
      _ring.value = 1;
      _check.value = 1;
      return;
    }
    _container.forward();
    _ring.forward().whenComplete(() {
      if (mounted) {
        _check.forward();
      }
    });
  }

  @override
  void dispose() {
    _container.dispose();
    _ring.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleCurve = CurvedAnimation(parent: _container, curve: Curves.elasticOut);
    return AnimatedBuilder(
      animation: Listenable.merge([_container, _ring, _check]),
      builder: (context, _) {
        final scale = 0.85 + 0.15 * scaleCurve.value;
        final alpha = (0.4 + 0.6 * _container.value).clamp(0.0, 1.0);
        return Opacity(
          opacity: alpha,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                gradient: LinearGradient(
                  colors: widget.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: SizedBox.square(
                dimension: widget.size * 0.56,
                child: CustomPaint(
                  painter: _SuccessPainter(
                    ring: CurvedAnimation(parent: _ring, curve: VxMotion.easeOut).value,
                    check: CurvedAnimation(parent: _check, curve: VxMotion.easeOut).value,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({required this.ring, required this.check});

  final double ring;
  final double check;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.95);
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, 2 * math.pi * ring, false, paint);

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.36);
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remaining = total * check;
    final partial = Path();
    for (final ui.PathMetric m in metrics) {
      if (remaining <= 0) {
        break;
      }
      partial.addPath(m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
      remaining -= m.length;
    }
    canvas.drawPath(partial, paint..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SuccessPainter old) => old.ring != ring || old.check != check;
}
