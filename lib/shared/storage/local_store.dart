import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _kSelectedCountries = 'selectedCountries';
  static const _kCitiesByCountry = 'citiesByCountry';

  // ✅ Visit metadata
  static const _kCountryVisitedOn = 'countryVisitedOn'; // Map<String, String ISO>
  static const _kCityVisitedOn = 'cityVisitedOn'; // Map<String, Map<String, String ISO>>
  static const _kCityNotes = 'cityNotes'; // Map<String, Map<String, String>>
  static const _kLastNotifyIso2 = 'last_notify_iso2';
  static const _kLastNotifyTs = 'last_notify_ts';

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
      final inner = (e.value as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
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
      final inner = (e.value as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
      out[e.key] = Map<String, String>.from(inner);
    }
    return out;
  }

  static Future<LastCountryNotify?> loadLastCountryNotify() async {
    final sp = await SharedPreferences.getInstance();
    final iso2 = sp.getString(_kLastNotifyIso2);
    final ts = sp.getInt(_kLastNotifyTs);
    if (iso2 == null || ts == null) return null;
    return LastCountryNotify(iso2: iso2, timestampMs: ts);
  }

  static Future<void> saveLastCountryNotify({
    required String iso2,
    required int timestampMs,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastNotifyIso2, iso2);
    await sp.setInt(_kLastNotifyTs, timestampMs);
  }

  static Future<bool> hasGuestData() async {
    final selected = await loadSelectedCountries();
    if (selected.isNotEmpty) return true;

    final cities = await loadCitiesByCountry();
    for (final v in cities.values) {
      if (v.isNotEmpty) return true;
    }
    return false;
  }

  /// Clears all travel selection + metadata (used on logout or overwrite).
  static Future<void> clearSelectionData() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kSelectedCountries);
    await sp.remove(_kCitiesByCountry);
    await sp.remove(_kCountryVisitedOn);
    await sp.remove(_kCityVisitedOn);
    await sp.remove(_kCityNotes);
    await sp.remove(_kLastNotifyIso2);
    await sp.remove(_kLastNotifyTs);
  }

  // ==========================================================
  // ✅ New: snapshot export/import for server backup/hydration
  // ==========================================================

  static Future<Map<String, dynamic>> exportToJson() async {
    final selected = await loadSelectedCountries();
    final cities = await loadCitiesByCountry();
    final countryVisitedOn = await loadCountryVisitedOn();
    final cityVisitedOn = await loadCityVisitedOn();
    final cityNotes = await loadCityNotes();
    final lastNotify = await loadLastCountryNotify();

    return {
      'selectedCountries': selected.toList(),
      'citiesByCountry': cities,
      'countryVisitedOn': countryVisitedOn,
      'cityVisitedOn': cityVisitedOn,
      'cityNotes': cityNotes,
      'lastCountryNotify': lastNotify == null
          ? null
          : {
        'iso2': lastNotify.iso2,
        'timestampMs': lastNotify.timestampMs,
      },
    };
  }

  /// Overwrites local store from a snapshot JSON (server hydration).
  static Future<void> importFromJson(Map<String, dynamic> json) async {
    // Overwrite behavior (your rule)
    await clearSelectionData();

    final selectedList = (json['selectedCountries'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        const <String>[];
    await saveSelectedCountries(selectedList.toSet());

    final citiesRaw = json['citiesByCountry'];
    if (citiesRaw is Map) {
      final cities = <String, List<String>>{};
      for (final entry in citiesRaw.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is List) {
          cities[key] = val.map((e) => e.toString()).toList();
        }
      }
      await saveCitiesByCountry(cities);
    }

    final cvoRaw = json['countryVisitedOn'];
    if (cvoRaw is Map) {
      final map = <String, String>{};
      for (final e in cvoRaw.entries) {
        map[e.key.toString()] = e.value.toString();
      }
      await saveCountryVisitedOn(map);
    }

    final cityVisitedRaw = json['cityVisitedOn'];
    if (cityVisitedRaw is Map) {
      final out = <String, Map<String, String>>{};
      for (final e in cityVisitedRaw.entries) {
        final country = e.key.toString();
        final inner = <String, String>{};
        final v = e.value;
        if (v is Map) {
          for (final innerE in v.entries) {
            inner[innerE.key.toString()] = innerE.value.toString();
          }
        }
        out[country] = inner;
      }
      await saveCityVisitedOn(out);
    }

    final notesRaw = json['cityNotes'];
    if (notesRaw is Map) {
      final out = <String, Map<String, String>>{};
      for (final e in notesRaw.entries) {
        final country = e.key.toString();
        final inner = <String, String>{};
        final v = e.value;
        if (v is Map) {
          for (final innerE in v.entries) {
            inner[innerE.key.toString()] = innerE.value.toString();
          }
        }
        out[country] = inner;
      }
      await saveCityNotes(out);
    }

    final ln = json['lastCountryNotify'];
    if (ln is Map) {
      final iso2 = ln['iso2']?.toString();
      final ts = ln['timestampMs'];
      final tsInt = ts is int ? ts : int.tryParse(ts?.toString() ?? '');
      if (iso2 != null && tsInt != null) {
        await saveLastCountryNotify(iso2: iso2, timestampMs: tsInt);
      }
    }
  }
}

class LastCountryNotify {
  final String iso2;
  final int timestampMs;
  LastCountryNotify({required this.iso2, required this.timestampMs});
}
