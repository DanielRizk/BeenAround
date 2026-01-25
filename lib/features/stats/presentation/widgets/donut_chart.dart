import 'dart:math';
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  final double percent;
  final double size;

  const DonutChart({
    super.key,
    required this.percent,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DonutPainter(
        percent: percent,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  final Color color;

  _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.grey.withOpacity(0.2);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect.deflate(stroke / 2), 0, 2 * pi, false, bgPaint);
    canvas.drawArc(rect.deflate(stroke / 2), -pi / 2,
        2 * pi * percent.clamp(0, 1), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
