import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../../../../shared/map/world_map_models.dart';

class WorldMapLabelsPainter extends CustomPainter {
  final WorldMapData map;
  final TransformationController controller;

  // tune these if you want
  final double fontSize;
  final double minCountryScreenWidth;
  final double minCountryScreenHeight;

  final Map<String, Offset> anchors;

  final Color strokeColor;


  WorldMapLabelsPainter({
    required this.map,
    required this.controller,
    this.fontSize = 12,
    this.minCountryScreenWidth = 14,
    this.minCountryScreenHeight = 8,
    required this.anchors,
    required this.strokeColor
  }) : super(repaint: controller); // ✅ repaint on pan/zoom

  @override
  void paint(Canvas canvas, Size size) {
    // Text stroke (white)
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = strokeColor
      ..strokeJoin = StrokeJoin.round;

    // Text fill (same grey as countries)
    const fillColor = Color(0xFF9E9E9E);

    for (final c in map.countries) {
      final screenRect = _transformRect(controller.value, c.bounds);

      // ✅ Hide label if country too small on screen
      if (screenRect.width < minCountryScreenWidth ||
          screenRect.height < minCountryScreenHeight) {
        continue;
      }

      // Label anchor: center of country bounds
      final worldCenter = anchors[c.id] ?? c.bounds.center;
      final screenCenter = _transformPoint(controller.value, worldCenter);

      final label = c.id;

      // Build text painters once per country
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: fontSize,
          color: fillColor,
          // We'll paint stroke manually using foreground on a second painter below
        ),
      );

      final tpFill = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      // Measure and ensure it fits inside the country screen rect.
      // If it doesn't fit, hide.
      final textW = tpFill.width;
      final textH = tpFill.height;

      if (textW > screenRect.width * 0.3 || textH > screenRect.height * 0.3) {
        continue;
      }

      // Position so text is centered at screenCenter
      final topLeft = Offset(
        screenCenter.dx - textW / 2,
        screenCenter.dy - textH / 2,
      );

      // Optional: Avoid painting outside screen bounds
      if (topLeft.dx + textW < 0 ||
          topLeft.dy + textH < 0 ||
          topLeft.dx > size.width ||
          topLeft.dy > size.height) {
        continue;
      }

      // Paint stroke
      final tpStroke = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: fontSize,
            foreground: strokePaint,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tpStroke.paint(canvas, topLeft);

      // Paint fill
      tpFill.paint(canvas, topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapLabelsPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.controller != controller ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.minCountryScreenWidth != minCountryScreenWidth ||
        oldDelegate.minCountryScreenHeight != minCountryScreenHeight;
  }

  Offset _transformPoint(Matrix4 m, Offset p) {
    final v = m.transform3(vector_math.Vector3(p.dx, p.dy, 0));
    return Offset(v.x, v.y);
  }

  Rect _transformRect(Matrix4 m, Rect r) {
    final p1 = _transformPoint(m, r.topLeft);
    final p2 = _transformPoint(m, r.topRight);
    final p3 = _transformPoint(m, r.bottomLeft);
    final p4 = _transformPoint(m, r.bottomRight);

    final minX = math.min(math.min(p1.dx, p2.dx), math.min(p3.dx, p4.dx));
    final maxX = math.max(math.max(p1.dx, p2.dx), math.max(p3.dx, p4.dx));
    final minY = math.min(math.min(p1.dy, p2.dy), math.min(p3.dy, p4.dy));
    final maxY = math.max(math.max(p1.dy, p2.dy), math.max(p3.dy, p4.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
