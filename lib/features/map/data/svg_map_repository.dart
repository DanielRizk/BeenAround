import 'package:flutter/services.dart';

class SvgMapRepository {
  /// Builds a template SVG once, where stroke-width is a placeholder token.
  Future<String> loadWorldMapTemplate(String assetPath) async {
    var svg = await rootBundle.loadString(assetPath);

    // Remove embedded CSS blocks if any
    svg = svg.replaceAll(
      RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false),
      '',
    );

    // Inject paint into each path with a stroke-width placeholder: __SW__
    svg = svg.replaceAllMapped(
      RegExp(r'<path\b([^>]*?)(\/?)>', caseSensitive: false),
          (m) {
        var attrs = m.group(1) ?? '';
        final isSelfClosing = (m.group(2) ?? '') == '/';

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

        // IMPORTANT: stroke-width placeholder token __SW__
        const paint =
            ' fill="#9E9E9E" stroke="#FFFFFF" stroke-width="__SW__" '
            'stroke-linejoin="round" stroke-linecap="round"';

        return '<path$attrs$paint${isSelfClosing ? " /" : ""}>';
      },
    );

    return svg;
  }
}
