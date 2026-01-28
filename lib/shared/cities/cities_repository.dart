import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class CitiesRepository {
  static Future<Map<String, List<String>>> loadIso2ToCities(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(raw);

    final map = <String, List<String>>{};
    for (final row in rows) {
      if (row.length < 2 || row.contains("=")) continue;
      final iso2 = row[0].toString().trim().toUpperCase();
      final city = row[1].toString().trim();
      if (iso2.isEmpty || city.isEmpty) continue;
      (map[iso2] ??= <String>[]).add(city);
    }

    // Optional: sort and dedupe
    for (final e in map.entries) {
      final uniq = e.value.toSet().toList()..sort((a, b) => a.compareTo(b));
      map[e.key] = uniq;
    }

    return map;
  }
}
