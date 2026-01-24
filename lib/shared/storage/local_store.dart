import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _kSelectedCountries = 'selectedCountries';
  static const _kCitiesByCountry = 'citiesByCountry';

  // ✅ New: visit metadata
  static const _kCountryVisitedOn = 'countryVisitedOn'; // Map<String, String ISO>
  static const _kCityVisitedOn = 'cityVisitedOn'; // Map<String, Map<String, String ISO>>
  static const _kCityNotes = 'cityNotes'; // Map<String, Map<String, String>>

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

  // =========================
  // Visit metadata persistence
  // =========================

  static Future<void> saveCountryVisitedOn(Map<String, String> map) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCountryVisitedOn, jsonEncode(map));
  }

  static Future<Map<String, String>> loadCountryVisitedOn() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCountryVisitedOn);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  static Future<void> saveCityVisitedOn(Map<String, Map<String, String>> map) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCityVisitedOn, jsonEncode(map));
  }

  static Future<Map<String, Map<String, String>>> loadCityVisitedOn() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCityVisitedOn);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, Map<String, String>>{};
    for (final e in decoded.entries) {
      final inner = (e.value as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      out[e.key] = Map<String, String>.from(inner);
    }
    return out;
  }

  static Future<void> saveCityNotes(Map<String, Map<String, String>> map) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCityNotes, jsonEncode(map));
  }

  static Future<Map<String, Map<String, String>>> loadCityNotes() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCityNotes);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, Map<String, String>>{};
    for (final e in decoded.entries) {
      final inner = (e.value as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      out[e.key] = Map<String, String>.from(inner);
    }
    return out;
  }

  static Future<void> clearSelectionData() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kSelectedCountries);
    await sp.remove(_kCitiesByCountry);

    // ✅ New
    await sp.remove(_kCountryVisitedOn);
    await sp.remove(_kCityVisitedOn);
    await sp.remove(_kCityNotes);
  }
}
