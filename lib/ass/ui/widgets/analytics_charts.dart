import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Efficiency trend: horizontal grid, filled area, line and point markers.
class PortfolioTrendChart extends StatelessWidget {
  const PortfolioTrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.gridColor,
  });

  final List<double> points;
  final Color color;
  final Color gridColor;

  @override
  Widget build(BuildContext context) {
    final series = points.isEmpty ? const [0.0, 0.2, 0.35, 0.5, 0.55] : points;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        painter: _TrendPainter(series, color, gridColor, t),
        size: Size.infinite,
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.series, this.color, this.gridColor, this.t);

  final List<double> series;
  final Color color;
  final Color gridColor;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Path();
    final area = Path();
    final dots = <Offset>[];
    final n = math.max(series.length - 1, 1);
    for (var i = 0; i < series.length; i++) {
      final x = size.width * i / n;
      final y = size.height * (1 - (series[i].clamp(0.0, 1.0) * t));
      dots.add(Offset(x, y));
      if (i == 0) {
        line.moveTo(x, y);
        area
          ..moveTo(x, size.height)
          ..lineTo(x, y);
      } else {
        line.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area
      ..lineTo(size.width, size.height)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = color.withValues(alpha: 0.12))
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
    for (final d in dots) {
      canvas.drawCircle(d, 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.t != t || old.series != series || old.color != color || old.gridColor != gridColor;
}

/// Portfolio health donut.
class PortfolioDonutChart extends StatelessWidget {
  const PortfolioDonutChart({
    super.key,
    required this.percent,
    required this.color,
    required this.track,
  });

  final int percent;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent.clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(painter: _DonutPainter(v, color, track)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.progress, this.color, this.track);

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final d = math.min(size.width, size.height) - stroke;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: d, height: d);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas
      ..drawArc(rect, 0, 2 * math.pi, false, paint..color = track)
      ..drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.color != color || old.track != track;
}
