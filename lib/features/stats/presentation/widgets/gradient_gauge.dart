import 'dart:math';
import 'package:flutter/material.dart';

class GradientGauge extends StatelessWidget {
  final int visited;
  final int total;
  final double size;
  final String? title; // optional text under gauge

  const GradientGauge({
    super.key,
    required this.visited,
    required this.total,
    this.size = 96,
    this.title,
  });

  double get _percent => (total == 0) ? 0.0 : (visited / total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final pct = (_percent * 100).round();

    // 👇 relative font sizes
    final pctFontSize = size * 0.24;   // percentage text
    final ratioFontSize = size * 0.12; // visited/total text

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: _GaugePainter(
            percent: _percent,
            stroke: size * 0.12,
            trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            progressColor: Theme.of(context).colorScheme.primary,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: pctFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$visited/$total',
                    style: TextStyle(
                      fontSize: ratioFontSize,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 8),
          Text(
            title!,
            style: Theme.of(context).textTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent; // 0..1
  final double stroke;
  final Color trackColor;
  final Color progressColor;

  _GaugePainter({
    required this.percent,
    required this.stroke,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (min(size.width, size.height) / 2) - stroke / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    // Track (full circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      trackPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percent.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.stroke != stroke ||
        oldDelegate.trackColor != trackColor;
  }
}
