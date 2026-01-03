import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _kSelectedCountries = 'selectedCountries';
  static const _kCitiesByCountry = 'citiesByCountry';

  static Future<void> saveSelectedCountries(Set<String> ids) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kSelectedCountries, ids.toList());
  }

  static Future<Set<String>> loadSelectedCountries() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kSelectedCountries) ?? const <String>[];
    return list.toSet();
  }

  static Future<void> saveCitiesByCountry(Map<String, List<String>> map) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCitiesByCountry, jsonEncode(map));
  }

  static Future<Map<String, List<String>>> loadCitiesByCountry() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCitiesByCountry);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  static Future<void> clearSelectionData() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kSelectedCountries);
    await sp.remove(_kCitiesByCountry);
  }
}
