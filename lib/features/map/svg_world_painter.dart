import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'svg_world_loader.dart';

class SvgWorldPainter extends CustomPainter {
  final SvgWorld world;
  final Set<String> visitedCountries;
  final double viewportScale;

  final bool showLabels;
  final Map<String, String> countryLabels;

  SvgWorldPainter({
    required this.world,
    required this.visitedCountries,
    required this.viewportScale,
    this.showLabels = true,
    this.countryLabels = const {},
  });

  // Cache boundary samples per Path identity to avoid heavy recomputation
  static final Map<int, List<Offset>> _boundaryCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    // Fit viewBox into canvas (your original logic)
    final scaleX = size.width / world.viewBox.width;
    final scaleY = size.height / world.viewBox.height;
    final fitScale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (size.width - world.viewBox.width * fitScale) / 2.0;
    final dy = (size.height - world.viewBox.height * fitScale) / 2.0;

    canvas.translate(dx, dy);
    canvas.scale(fitScale, fitScale);
    canvas.translate(-world.viewBox.left, -world.viewBox.top);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 / viewportScale // <-- your key line (kept)
      ..isAntiAlias = true
      ..color = Colors.black.withOpacity(0.15);

    for (final c in world.countries) {
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = visitedCountries.contains(c.id)
            ? Colors.orange.withOpacity(0.7)
            : Colors.grey.withOpacity(0.35);

      canvas.drawPath(c.path, fill);
      canvas.drawPath(c.path, borderPaint);
    }

    if (showLabels && countryLabels.isNotEmpty) {
      _paintLabels(canvas, fitScale: fitScale);
    }
  }

  void _paintLabels(Canvas canvas, {required double fitScale}) {
    // Only show labels if country is large enough ON SCREEN
    const minScreenWidth = 70.0;
    const minScreenHeight = 32.0;

    // Constant screen font size (px) — does not change with zoom
    const double desiredScreenFontPx = 50.0;

    // Constant screen stroke thickness (px)
    const double desiredStrokePx = 3.5;

    final double fontInSvgSpace = desiredScreenFontPx / viewportScale;
    final double strokeInSvgSpace = desiredStrokePx / viewportScale;

    for (final c in world.countries) {
      final name = countryLabels[c.id];
      if (name == null || name.isEmpty) continue;

      final bounds = c.path.getBounds();
      final screenW = bounds.width * fitScale * viewportScale;
      final screenH = bounds.height * fitScale * viewportScale;

      if (screenW < minScreenWidth || screenH < minScreenHeight) continue;

      // Avoid long names until zoomed in a bit
      if (name.length > 18 && viewportScale < 2.0) continue;

      // Pick a good point inside the country (works better for Canada/US)
      final anchor = _bestInteriorPoint(c.path);

      // Stroke painter (white outline)
      final strokePainter = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontSize: fontInSvgSpace,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeInSvgSpace
              ..strokeJoin = StrokeJoin.round
              ..isAntiAlias = true
              ..color = Colors.white,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: bounds.width);

      // Fill painter (dark text)
      final fillPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontSize: fontInSvgSpace,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.70),
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: bounds.width);

      // If it won't fit in SVG-space bounds, skip
      if (fillPainter.width > bounds.width) continue;

      final pos = Offset(
        anchor.dx - fillPainter.width / 2,
        anchor.dy - fillPainter.height / 2,
      );

      // Paint stroke then fill
      strokePainter.paint(canvas, pos);
      fillPainter.paint(canvas, pos);
    }
  }

  /// Robust label anchor: pick the point inside the path with the largest
  /// distance to the boundary (approx). Much better for multi-part/holey shapes.
  Offset _bestInteriorPoint(Path path) {
    final b = path.getBounds();
    final center = b.center;

    // If center is inside, it's already great (fast path)
    if (path.contains(center)) return center;

    // Pre-sample boundary points (cached)
    final boundary = _getBoundarySamples(path);

    // Grid sampling over bounds
    // More samples = better centering, but heavier. This is a good balance.
    final int cols = 22;
    final int rows = 14;

    Offset best = center;
    double bestScore = -1;

    for (int yi = 0; yi <= rows; yi++) {
      final y = b.top + (b.height * yi / rows);
      for (int xi = 0; xi <= cols; xi++) {
        final x = b.left + (b.width * xi / cols);
        final p = Offset(x, y);

        if (!path.contains(p)) continue;

        // Score = distance to nearest boundary sample (bigger is better)
        final d = _minDistToBoundary(p, boundary);

        if (d > bestScore) {
          bestScore = d;
          best = p;
        }
      }
    }

    // If grid didn't find anything (rare), fallback to any inside point
    if (bestScore < 0) {
      // Small spiral fallback
      final step = math.max(1.0, math.min(b.width, b.height) / 18.0);
      final maxR = math.max(b.width, b.height) / 2.0;
      const angles = 24;

      for (double r = step; r <= maxR; r += step) {
        for (int i = 0; i < angles; i++) {
          final a = (i / angles) * math.pi * 2;
          final p = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
          if (path.contains(p)) return p;
        }
      }
      return center;
    }

    return best;
  }

  List<Offset> _getBoundarySamples(Path path) {
    final key = identityHashCode(path);
    final cached = _boundaryCache[key];
    if (cached != null) return cached;

    final out = <Offset>[];

    // Sample points along all contours
    for (final metric in path.computeMetrics(forceClosed: false)) {
      final len = metric.length;
      // sampling density: more for longer boundaries
      final int steps = math.max(60, (len / 8).round());
      for (int i = 0; i <= steps; i++) {
        final t = len * (i / steps);
        final pos = metric.getTangentForOffset(t)?.position;
        if (pos != null) out.add(pos);
      }
    }

    // Safety fallback: if somehow empty
    if (out.isEmpty) {
      final b = path.getBounds();
      out.addAll([
        b.topLeft,
        b.topRight,
        b.bottomLeft,
        b.bottomRight,
        b.center,
      ]);
    }

    _boundaryCache[key] = out;
    return out;
  }

  double _minDistToBoundary(Offset p, List<Offset> boundary) {
    double best = double.infinity;
    for (final q in boundary) {
      final dx = p.dx - q.dx;
      final dy = p.dy - q.dy;
      final d2 = dx * dx + dy * dy;
      if (d2 < best) best = d2;
    }
    return math.sqrt(best);
  }

  @override
  bool shouldRepaint(covariant SvgWorldPainter oldDelegate) {
    return oldDelegate.visitedCountries != visitedCountries ||
        oldDelegate.viewportScale != viewportScale ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.countryLabels != countryLabels;
  }
}
