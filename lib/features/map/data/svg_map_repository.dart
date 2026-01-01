import 'package:flutter/services.dart';
import '../domain/country_info.dart';

class SvgMapRepository {
  // Cache original SVG text in memory to avoid reloading from bundle repeatedly
  String? _rawCache;

  Future<String> _loadRaw(String assetPath) async {
    _rawCache ??= await rootBundle.loadString(assetPath);
    return _rawCache!;
  }

  List<CountryInfo>? _countriesCache;

  /// Extract countries from the SVG:
  /// - id="AF"
  /// - title="Afghanistan"
  Future<List<CountryInfo>> extractCountries(String assetPath) async {
    if (_countriesCache != null) return _countriesCache!;
    final raw = await _loadRaw(assetPath);

    // Match each <path ...> tag
    final pathTag = RegExp(r'<path\b([^>]*)\/?>', caseSensitive: false);

    String? _attr(String attrs, String name) {
      final m = RegExp('$name="([^"]+)"', caseSensitive: false).firstMatch(attrs);
      return m?.group(1);
    }

    final list = <CountryInfo>[];

    for (final m in pathTag.allMatches(raw)) {
      final attrs = m.group(1) ?? '';

      final id = (_attr(attrs, 'id') ?? '').trim().toUpperCase();
      final title = (_attr(attrs, 'title') ?? '').trim();

      // keep only ISO2-like ids
      if (id.length == 2 && title.isNotEmpty) {
        list.add(CountryInfo(id: id, name: title));
      }
    }

    // remove duplicates (some SVGs may repeat)
    final byId = <String, CountryInfo>{};
    for (final c in list) {
      byId[c.id] = c;
    }

    final result = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    _countriesCache = list;
    return result;
  }

  /// Build SVG string with:
  /// - grey fill for unselected countries
  /// - orange fill for selected countries
  /// - white borders with stroke width placeholder __SW__
  Future<String> buildTemplateSvg(
      String assetPath, {
        required Set<String> selectedIds,
      }) async {
    var svg = await _loadRaw(assetPath);

    // Remove embedded CSS blocks if any (optional)
    svg = svg.replaceAll(
      RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false),
      '',
    );

    svg = svg.replaceAllMapped(
      RegExp(r'<path\b([^>]*?)(\/?)>', caseSensitive: false),
          (m) {
        var attrs = m.group(1) ?? '';
        final isSelfClosing = (m.group(2) ?? '') == '/';

        // Extract id="XX" from attrs
        final idMatch = RegExp(r'\bid="([^"]+)"', caseSensitive: false).firstMatch(attrs);
        final id = (idMatch?.group(1) ?? '').toUpperCase();

        // Strip conflicting paint attrs
        attrs = attrs
            .replaceAll(RegExp(r'\sfill="[^"]*"', caseSensitive: false), '')
            .replaceAll(RegExp(r"\sfill='[^']*'", caseSensitive: false), '')
            .replaceAll(RegExp(r'\sstroke="[^"]*"', caseSensitive: false), '')
            .replaceAll(RegExp(r"\sstroke='[^']*'", caseSensitive: false), '')
            .replaceAll(RegExp(r'\sstroke-width="[^"]*"', caseSensitive: false), '')
            .replaceAll(RegExp(r"\sstroke-width='[^']*'", caseSensitive: false), '')
            .replaceAll(RegExp(r'\sstyle="[^"]*"', caseSensitive: false), '')
            .replaceAll(RegExp(r"\sstyle='[^']*'", caseSensitive: false), '');

        final fill = selectedIds.contains(id) ? '#FF9800' : '#9E9E9E'; // orange / grey

        final paint =
            ' fill="$fill" stroke="#FFFFFF" stroke-width="__SW__" '
            'stroke-linejoin="round" stroke-linecap="round"';

        return '<path$attrs$paint${isSelfClosing ? " /" : ""}>';
      },
    );

    return svg;
  }
}
