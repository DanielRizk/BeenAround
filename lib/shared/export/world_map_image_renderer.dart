import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../features/map/widgets/world_map_painter.dart';
import '../map/world_map_models.dart';

/// Renders the world map to a PNG **independently** of whatever the user is
/// currently zooming/panning on screen.
///
/// The on-screen map is drawn inside an [InteractiveViewer]. For PDF export we
/// want a stable, full-world image every time.
class WorldMapImageRenderer {
  /// Render a full-world PNG.
  ///
  /// - [pixelSize] controls the output resolution (higher = sharper in PDF).
  /// - The map is scaled with `BoxFit.contain` and centered.
  static Future<Uint8List> renderPng({
    required WorldMapData map,
    required Set<String> selectedIds,
    required Color selectedColor,
    required bool multicolor,
    required List<Color> palette,
    required Color borderColor,
    Size pixelSize = const Size(2400, 1200),
  }) async {
    final outW = pixelSize.width.round().clamp(1, 1000000);
    final outH = pixelSize.height.round().clamp(1, 1000000);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final mapSize = map.canvasSize;

    // Fit full map into output image (contain + center)
    final sx = (outW / mapSize.width).isFinite ? outW / mapSize.width : 1.0;
    final sy = (outH / mapSize.height).isFinite ? outH / mapSize.height : 1.0;
    final fit = (sx < sy ? sx : sy).clamp(0.0001, 1e9);

    final dx = (outW - mapSize.width * fit) / 2.0;
    final dy = (outH - mapSize.height * fit) / 2.0;

    // Reuse existing painter so PDF map colors are identical to on-screen map.
    // The painter uses controller scale for border thickness, so we provide one.
    final tc = TransformationController(
      Matrix4.identity()
        ..translate(dx, dy)
        ..scale(fit),
    );

    final painter = WorldMapPainter(
      map: map,
      selectedIds: selectedIds,
      controller: tc,
      selectedColor: selectedColor,
      multicolor: multicolor,
      palette: palette,
      borderColor: borderColor,
    );

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(fit);
    painter.paint(canvas, mapSize);
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(outW, outH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
