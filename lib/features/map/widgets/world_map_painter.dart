import 'package:flutter/material.dart';
import '../../../../shared/map/world_map_models.dart';

class WorldMapPainter extends CustomPainter {
  final WorldMapData map;
  final Set<String> selectedIds;
  final TransformationController controller;
  final Color selectedColor;
  final bool multicolor;
  final List<Color> palette;
  final Color borderColor;

  WorldMapPainter({
    required this.map,
    required this.selectedIds,
    required this.controller,
    required this.selectedColor,
    required this.multicolor,
    required this.palette,
    required this.borderColor,
  }) : super(repaint: controller);

  int _fnv1a32(String s) {
    // Stable hash across sessions/platforms (unlike String.hashCode).
    const int fnvPrime = 0x01000193; // 16777619
    int hash = 0x811C9DC5; // 2166136261
    for (final codeUnit in s.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash;
  }

  int _paletteIndexForCountry(String name) {
    final normalized = name.trim().toLowerCase();
    final h = _fnv1a32(normalized);
    final len = palette.isEmpty ? 1 : palette.length;
    return h % len;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = controller.value.getMaxScaleOnAxis().clamp(0.0001, 1e9);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = borderColor
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..strokeWidth = 0.5 / scale;

    for (final c in map.countries) {
      if (selectedIds.contains(c.id)) {
        fillPaint.color =
        multicolor ? palette[_paletteIndexForCountry(c.name)] : selectedColor;
      } else {
        fillPaint.color = const Color(0xFF9E9E9E);
      }
      canvas.drawPath(c.path, fillPaint);
      canvas.drawPath(c.path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter old) {
    // palette compare (fast enough: only 8 colors)
    bool paletteChanged = old.palette.length != palette.length;
    if (!paletteChanged) {
      for (int i = 0; i < palette.length; i++) {
        if (old.palette[i].toARGB32() != palette[i].toARGB32()) {
          paletteChanged = true;
          break;
        }
      }
    }

    return old.map != map ||
        old.selectedIds != selectedIds ||
        old.controller != controller ||
        old.multicolor != multicolor ||
        paletteChanged ||
        old.selectedColor.toARGB32() != selectedColor.toARGB32();
  }
}
