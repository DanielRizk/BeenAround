import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_style.dart';

class LivingBackground extends StatefulWidget {
  const LivingBackground({super.key, required this.child});

  final Widget child;

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _bg = AnimationController(
    vsync: this,
    duration: Duration(seconds: context.style.bgLoopSeconds),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ reacts immediately when theme/style changes (no “wait until scroll”)
    final seconds = context.style.bgLoopSeconds;
    if (_bg.duration?.inSeconds != seconds) {
      _bg.duration = Duration(seconds: seconds);
      if (!_bg.isAnimating) _bg.repeat();
    }
  }

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    return AnimatedBuilder(
      animation: _bg,
      builder: (_, __) {
        final t = _bg.value * 2 * math.pi;

        // seamless loop
        final a = math.sin(t) * .5 + .5;
        final b = math.cos(t * 2) * .5 + .5;
        final c = math.sin(t * 3) * .5 + .5;

        return CustomPaint(
          painter: _LivingBackgroundPainter(
            a: a,
            b: b,
            c: c,
            primary: cs.primary,
            secondary: cs.secondary,
            surface: cs.surface,
            isDark: theme.brightness == Brightness.dark,
            blobOpacity: style.backgroundBlobOpacity,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _LivingBackgroundPainter extends CustomPainter {
  _LivingBackgroundPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.isDark,
    required this.blobOpacity,
  });

  final double a, b, c;
  final Color primary, secondary, surface;
  final bool isDark;
  final double blobOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);

    void blob(Offset center, double radius, Color color, double opacity) {
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity));
    }

    final w = size.width, h = size.height;
    final base = blobOpacity * (isDark ? 1.35 : 1.0);

    blob(Offset(w * (0.20 + 0.08 * a), h * (0.18 + 0.06 * b)), w * (0.52 + 0.06 * c), primary, base * 1.00);
    blob(Offset(w * (0.92 - 0.10 * b), h * (0.24 + 0.10 * c)), w * (0.38 + 0.05 * a), secondary, base * 0.80);
    blob(Offset(w * (0.55 + 0.12 * c), h * (1.05 - 0.12 * a)), w * (0.55 + 0.04 * b), primary, base * 0.65);
  }

  @override
  bool shouldRepaint(covariant _LivingBackgroundPainter old) =>
      old.a != a ||
          old.b != b ||
          old.c != c ||
          old.primary != primary ||
          old.secondary != secondary ||
          old.surface != surface ||
          old.isDark != isDark ||
          old.blobOpacity != blobOpacity;
}