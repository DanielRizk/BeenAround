import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

class CountryPath {
  final String id; // can be ISO code, or country name (from class), etc.
  final Path path;
  CountryPath({required this.id, required this.path});
}

class SvgWorld {
  final Rect viewBox;
  final List<CountryPath> countries;
  SvgWorld({required this.viewBox, required this.countries});
}

Future<SvgWorld> loadWorldSvg(String assetPath) async {
  final svgString = await rootBundle.loadString(assetPath);
  final doc = XmlDocument.parse(svgString);

  final svg = doc.findAllElements('svg').first;

  final viewBox = _parseViewBoxCaseInsensitive(svg);
  final countries = _collectAndMergeCountryPaths(doc);

  if (countries.isEmpty) {
    throw Exception(
      'No usable paths found. Expected id/class/name on <path> or parent <g id="...">.',
    );
  }

  return SvgWorld(viewBox: viewBox, countries: countries);
}

Rect _parseViewBoxCaseInsensitive(XmlElement svg) {
  // Some SVGs use "viewbox" instead of "viewBox"
  final viewBoxStr =
      svg.getAttribute('viewBox') ?? svg.getAttribute('viewbox');

  if (viewBoxStr != null && viewBoxStr.trim().isNotEmpty) {
    final vb = viewBoxStr
        .trim()
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.isNotEmpty)
        .map(double.parse)
        .toList();

    if (vb.length == 4) {
      return Rect.fromLTWH(vb[0], vb[1], vb[2], vb[3]);
    }
  }

  // Fallback to width/height
  double parseNum(String? s) {
    if (s == null) return 0;
    final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  final w = parseNum(svg.getAttribute('width'));
  final h = parseNum(svg.getAttribute('height'));

  if (w > 0 && h > 0) {
    return Rect.fromLTWH(0, 0, w, h);
  }

  throw Exception('SVG has no viewBox/viewbox and no usable width/height.');
}

List<CountryPath> _collectAndMergeCountryPaths(XmlDocument doc) {
  // Merge multiple <path> parts per country (islands etc.)
  final Map<String, Path> merged = {};

  for (final node in doc.descendants.whereType<XmlElement>()) {
    if (node.name.local != 'path') continue;

    final d = node.getAttribute('d');
    if (d == null || d.trim().isEmpty) continue;

    // Many world SVGs store country names in class=...
    // Your file specifically has tons of paths like: <path class="Canada" d="..."/>
    String? key = node.getAttribute('id');
    key = (key == null || key.isEmpty) ? node.getAttribute('class') : key;
    key = (key == null || key.isEmpty) ? node.getAttribute('name') : key;

    // Fallback: parent <g id="...">
    if (key == null || key.isEmpty) {
      final parent = node.parent;
      if (parent is XmlElement && parent.name.local == 'g') {
        final gid = parent.getAttribute('id');
        if (gid != null && gid.isNotEmpty) key = gid;
      }
    }

    if (key == null || key.isEmpty) continue;

    final part = parseSvgPathData(d);

    final existing = merged[key];
    if (existing == null) {
      merged[key] = part;
    } else {
      // Add as another contour into the same Path
      existing.addPath(part, Offset.zero);
    }
  }

  return merged.entries
      .map((e) => CountryPath(id: e.key, path: e.value))
      .toList();
}
