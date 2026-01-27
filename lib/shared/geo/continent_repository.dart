import 'package:flutter/services.dart';

class ContinentRepository {
  static Future<Map<String, String>> loadIso2ToContinent(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);

    final map = <String, String>{};
    final lines = raw.split(RegExp(r'\r?\n'));

    if (lines.isEmpty) return map;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip header line if it contains "iso" and "continent"
      final lower = line.toLowerCase();
      if (i == 0 && lower.contains('iso') && lower.contains('continent')) {
        continue;
      }

      // Supports comma OR semicolon separated
      final parts = line.split(RegExp(r'[;,]'));
      if (parts.length < 2) continue;

      var iso2 = parts[0].trim();
      var continent = parts[1].trim();

      // Remove possible quotes
      iso2 = iso2.replaceAll('"', '').replaceAll("'", '').toUpperCase();
      continent = continent.replaceAll('"', '').replaceAll("'", '');

      // Basic validation
      if (iso2.length != 2 || continent.isEmpty) continue;

      map[iso2] = continent;
    }

    return map;
  }
}
