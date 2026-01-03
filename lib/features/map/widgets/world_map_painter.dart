import 'package:flutter/material.dart';
import '../../../../shared/map/world_map_models.dart';

class WorldMapPainter extends CustomPainter {
  final WorldMapData map;
  final Set<String> selectedIds;
  final TransformationController controller;
  final Color selectedColor;

  WorldMapPainter({
    required this.map,
    required this.selectedIds,
    required this.controller,
    required this.selectedColor,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = controller.value.getMaxScaleOnAxis().clamp(0.0001, 1e9);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..strokeWidth = 0.5 / scale;

    for (final c in map.countries) {
      fillPaint.color =
      selectedIds.contains(c.id) ? selectedColor : const Color(0xFF9E9E9E);
      canvas.drawPath(c.path, fillPaint);
      canvas.drawPath(c.path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter old) {
    return old.map != map ||
        old.selectedIds != selectedIds ||
        old.controller != controller ||
        old.selectedColor.value != selectedColor.value;
  }
}
