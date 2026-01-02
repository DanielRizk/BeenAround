import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import '../../features/map/presentation/utils/label_anchor_finder.dart';
import 'world_map_models.dart';

class WorldMapLoader {
  static Future<WorldMapData> loadFromAsset(String assetPath) async {
    final svgText = await rootBundle.loadString(assetPath);
    return parseSvg(svgText);
  }

  static Future<WorldMapData> loadFromAssetWithAnchors(String assetPath) async {
    final data = await loadFromAsset(assetPath);

    // Compute anchors synchronously here (still before UI shows content)
    final anchors = <String, Offset>{};
    for (final c in data.countries) {
      anchors[c.id] = LabelAnchorFinder.findMainLandAnchor(
        path: c.path,
        bounds: c.bounds,
        grid: 40,
        borderSamples: 300,
      );
    }

    return data.copyWith(labelAnchorById: anchors);
  }

  static WorldMapData parseSvg(String svgText) {
    final doc = XmlDocument.parse(svgText);
    final svg = doc.rootElement;

    if (svg.name.local.toLowerCase() != 'svg') {
      throw StateError('Root element is not <svg>. Found: <${svg.name.local}>');
    }

    // 1) Try viewBox
    final viewBoxAttr = svg.getAttribute('viewBox') ?? svg.getAttribute('viewbox');
    Rect? viewBoxRect = _parseViewBox(viewBoxAttr);

    // Collect all <path> nodes
    final pathNodes = svg.findAllElements('path').toList();
    if (pathNodes.isEmpty) {
      throw StateError('SVG contains no <path> elements.');
    }

    // Parse paths first (we may need them for bounds fallback)
    final countries = <CountryShape>[];
    final nameById = <String, String>{};

    for (final node in pathNodes) {
      final id = node.getAttribute('id');
      final title = node.getAttribute('title');
      final d = node.getAttribute('d');

      if (id == null || id.trim().isEmpty) continue;
      if (d == null || d.trim().isEmpty) continue;

      final path = parseSvgPathData(d);
      final bounds = path.getBounds();

      final name = (title == null || title.trim().isEmpty) ? id.trim() : title.trim();

      countries.add(CountryShape(
        id: id.trim(),
        name: name,
        path: path,
        bounds: bounds,
      ));

      nameById[id.trim()] = name;
    }

    if (countries.isEmpty) {
      throw StateError('No valid <path> elements with id+d were parsed.');
    }

    // 2) If viewBox missing, try width/height
    if (viewBoxRect == null) {
      final w = _parseNumber(svg.getAttribute('width'));
      final h = _parseNumber(svg.getAttribute('height'));
      if (w != null && h != null && w > 0 && h > 0) {
        viewBoxRect = Rect.fromLTWH(0, 0, w, h);
      }
    }

    // 3) If still missing, compute bounds from all countries
    if (viewBoxRect == null) {
      Rect union = countries.first.bounds;
      for (final c in countries.skip(1)) {
        union = union.expandToInclude(c.bounds);
      }

      // Some SVGs have negative coords; normalize so top-left becomes (0,0)
      // We'll translate paths if needed.
      final dx = union.left < 0 ? -union.left : 0.0;
      final dy = union.top < 0 ? -union.top : 0.0;

      if (dx != 0.0 || dy != 0.0) {
        for (var i = 0; i < countries.length; i++) {
          final c = countries[i];
          final m = Matrix4.identity()..translate(dx, dy);
          final newPath = c.path.transform(m.storage);
          countries[i] = c.copyWith(
            path: newPath,
            bounds: newPath.getBounds(),
          );
        }

        // recompute union after shifting
        Rect newUnion = countries.first.bounds;
        for (final c in countries.skip(1)) {
          newUnion = newUnion.expandToInclude(c.bounds);
        }
        union = newUnion;
      }

      // Add a tiny padding so borders don’t clip
      const pad = 1.0;
      viewBoxRect = Rect.fromLTWH(
        union.left - pad,
        union.top - pad,
        math.max(1.0, union.width + 2 * pad),
        math.max(1.0, union.height + 2 * pad),
      );
    }

    final canvasSize = Size(viewBoxRect.width, viewBoxRect.height);

    return WorldMapData(
      canvasSize: canvasSize,
      countries: countries,
      nameById: nameById,
      viewBox: viewBoxRect,
      labelAnchorById: const {}, // ✅ empty for now
    );

  }

  static Rect? _parseViewBox(String? viewBox) {
    if (viewBox == null) return null;
    final parts = viewBox
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length != 4) return null;

    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    final w = double.tryParse(parts[2]);
    final h = double.tryParse(parts[3]);
    if (x == null || y == null || w == null || h == null) return null;
    if (w <= 0 || h <= 0) return null;
    return Rect.fromLTWH(x, y, w, h);
  }

  static double? _parseNumber(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;

    // handle "1000px", "1000", "1000.5"
    final cleaned = s.replaceAll('px', '').trim();
    return double.tryParse(cleaned);
  }
}
