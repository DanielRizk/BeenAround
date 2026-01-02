import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class MapTransformClamper {
  /// Clamps a transform so that the [contentSize] stays within [viewportSize].
  /// If the transformed content is smaller than the viewport on an axis, it is centered on that axis.
  static Matrix4 clampToViewport({
    required Matrix4 transform,
    required Size viewportSize,
    required Size contentSize,
  }) {
    final mapW = contentSize.width;
    final mapH = contentSize.height;

    final topLeft = _transformPoint(transform, const Offset(0, 0));
    final topRight = _transformPoint(transform, Offset(mapW, 0));
    final bottomLeft = _transformPoint(transform, Offset(0, mapH));
    final bottomRight = _transformPoint(transform, Offset(mapW, mapH));

    final minX = math.min(math.min(topLeft.dx, topRight.dx), math.min(bottomLeft.dx, bottomRight.dx));
    final maxX = math.max(math.max(topLeft.dx, topRight.dx), math.max(bottomLeft.dx, bottomRight.dx));
    final minY = math.min(math.min(topLeft.dy, topRight.dy), math.min(bottomLeft.dy, bottomRight.dy));
    final maxY = math.max(math.max(topLeft.dy, topRight.dy), math.max(bottomLeft.dy, bottomRight.dy));

    final viewW = viewportSize.width;
    final viewH = viewportSize.height;

    double dx = 0.0;
    double dy = 0.0;

    // Horizontal clamp / center
    if ((maxX - minX) <= viewW) {
      dx = (viewW - (maxX - minX)) / 2.0 - minX;
    } else {
      if (minX > 0) dx = -minX;
      if (maxX < viewW) dx = viewW - maxX;
    }

    // Vertical clamp / center
    if ((maxY - minY) <= viewH) {
      dy = (viewH - (maxY - minY)) / 2.0 - minY;
    } else {
      if (minY > 0) dy = -minY;
      if (maxY < viewH) dy = viewH - maxY;
    }

    if (dx == 0.0 && dy == 0.0) return transform;

    // Apply correction in viewport space (pre-multiply)
    final corrected = Matrix4.identity()
      ..translate(dx, dy)
      ..multiply(transform);

    return corrected;
  }

  static Offset _transformPoint(Matrix4 m, Offset p) {
    final v = m.transform3(Vector3(p.dx, p.dy, 0));
    return Offset(v.x, v.y);
  }
}
