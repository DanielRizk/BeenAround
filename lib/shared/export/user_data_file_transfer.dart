import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../storage/local_store.dart';

/// Optional hook so export can include {name, continent} for selectedCountries.
/// Provide this from wherever you have your country dataset loaded.
typedef CountryMetaResolver = Map<String, String>? Function(String iso2);

class UserDataFileTransfer {
  static const _channel = MethodChannel('been_around/saf_save');

  // ✅ New format
  static const String _format = 'register_export_data';
  static const int _version = 2;

  /// Optional: set this from app startup (e.g. after loading your country dataset).
  /// Must return: {'name': 'Germany', 'continent': 'Europe'} for a given ISO2, or null if unknown.
  static CountryMetaResolver? countryMetaResolver;

  /// Optional hook: call this after a successful import to let the app
  /// refresh its in-memory state / providers / controllers.
  ///
  /// Set this once during app startup, e.g.:
  /// UserDataFileTransfer.onImportApplied = () async => appController.reloadAllFromStorage();
  static Future<void> Function()? onImportApplied;

  // --- Keys that belong to travel_data_items (we will NOT put them in user_data_items) ---
  static const Set<String> _travelKeys = {
    'selectedCountries',
    'citiesByCountry',
    'countryVisitedOn',
    'cityVisitedOn',
    'cityNotes',
    // NOTE: lastCountryNotify is intentionally NOT in your v2 example.
    // If you later want it, add it to travel_data_items and here as well.
  };

  /// Exports SharedPreferences into the NEW v2 format:
  /// {
  ///   format, version, exportedAt,
  ///   travel_data_items: [...],
  ///   user_data_items: [...]
  /// }
  static Future<String> exportToFile() async {
    final payload = await _buildExportPayloadV2();

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);

    final result = await _channel.invokeMethod<String>(
      'saveTextFile',
      {
        'suggestedName': _suggestedName(),
        'mimeType': 'application/json',
        'text': jsonText,
      },
    );

    return result ?? 'Save canceled.';
  }

  static Future<String> exportToJsonString({bool pretty = false}) async {
    final payload = await _buildExportPayloadV2();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(payload);
    }
    return jsonEncode(payload);
  }

  static Future<Map<String, dynamic>> _buildExportPayloadV2() async {
    final sp = await SharedPreferences.getInstance();

    // -----------------------------
    // Build travel_data_items (v2)
    // -----------------------------
    final travelItems = await _buildTravelDataItemsV2();

    // -----------------------------
    // Build user_data_items (v2)
    // -----------------------------
    final userItems = <Map<String, dynamic>>[];

    final keys = sp.getKeys().toList()..sort();
    for (final key in keys) {
      if (_travelKeys.contains(key)) continue;

      final value = sp.get(key);

      if (value is String) {
        userItems.add({'key': key, 'type': 'string', 'value': value});
      } else if (value is int) {
        userItems.add({'key': key, 'type': 'int', 'value': value});
      } else if (value is double) {
        userItems.add({'key': key, 'type': 'double', 'value': value});
      } else if (value is bool) {
        userItems.add({'key': key, 'type': 'bool', 'value': value});
      } else if (value is List<String>) {
        userItems.add({'key': key, 'type': 'stringList', 'value': value});
      }
    }

    return <String, dynamic>{
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'travel_data_items': travelItems,
      'user_data_items': userItems,
    };
  }

  static Future<List<Map<String, dynamic>>> _buildTravelDataItemsV2() async {
    final citiesByCountry = await LocalStore.loadCitiesByCountry();
    final cityNotes = await LocalStore.loadCityNotes();
    final cityVisitedOn = await LocalStore.loadCityVisitedOn();
    final countryVisitedOn = await LocalStore.loadCountryVisitedOn();
    final selectedIso2 = await LocalStore.loadSelectedCountries();

    // v2 expects selectedCountries as an OBJECT keyed by ISO2 -> {name, continent}
    final selectedCountriesObj = <String, dynamic>{};
    for (final iso2 in selectedIso2) {
      final meta = countryMetaResolver?.call(iso2);
      selectedCountriesObj[iso2] = {
        'name': meta?['name'] ?? iso2, // fallback if no resolver set
        'continent': meta?['continent'] ?? '', // fallback if no resolver set
      };
    }

    return [
      {
        'key': 'citiesByCountry',
        'type': 'object',
        'value': citiesByCountry,
      },
      {
        'key': 'cityNotes',
        'type': 'object',
        'value': cityNotes,
      },
      {
        'key': 'cityVisitedOn',
        'type': 'object',
        'value': cityVisitedOn,
      },
      {
        'key': 'countryVisitedOn',
        'type': 'object',
        'value': countryVisitedOn,
      },
      {
        'key': 'selectedCountries',
        'type': 'object',
        'value': selectedCountriesObj,
      },
    ];
  }

  static String _suggestedName() {
    final now = DateTime.now();
    final ts =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'been_around_export_$ts.beenaround.json';
  }

  /// Imports a picked file in the NEW v2 format and repopulates:
  /// - LocalStore travel keys
  /// - user_data_items into SharedPreferences
  ///
  /// Behavior:
  /// - clears SharedPreferences entirely (single source of truth import)
  /// - then restores user_data_items
  /// - then writes travel_data_items via LocalStore
  ///
  /// After a successful import, calls [onImportApplied] so the app can reload
  /// in-memory state without requiring a full app restart.
  static Future<String> importFromPickedFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Been Around export file',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return 'Import canceled.';
    }

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      return 'Import failed: no file path received.';
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        return 'Import failed: file does not exist.';
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return 'Import failed: invalid JSON format.';
      }

      await _importFromDecodedV2(Map<String, dynamic>.from(decoded));
      await onImportApplied?.call();

      return 'Import done.';
    } on FormatException catch (e) {
      return 'Import failed: ${e.message}';
    } catch (e) {
      return 'Import failed: ${e.toString()}';
    }
  }

  /// Import from a JSON string (same format as the exported file).
  /// After a successful import, calls [onImportApplied] so the app can reload
  /// in-memory state without requiring a full app restart.
  static Future<String> importFromJsonString(String jsonText) async {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return 'Import failed: invalid JSON root (expected object).';
      }

      await _importFromDecodedV2(Map<String, dynamic>.from(decoded));
      await onImportApplied?.call();

      return 'Import done.';
    } on FormatException catch (e) {
      return 'Import failed: ${e.message}';
    } catch (e) {
      return 'Import failed: invalid JSON (${e.toString()}).';
    }
  }

  /// (Optional) Import directly from a file path (useful for tests or deep links).
  static Future<String> importFromFilePath(String path) async {
    if (path.isEmpty) return 'Import failed: empty file path.';

    try {
      final file = File(path);
      if (!await file.exists()) {
        return 'Import failed: file does not exist.';
      }
      final raw = await file.readAsString();
      return importFromJsonString(raw);
    } catch (e) {
      return 'Import failed: ${e.toString()}';
    }
  }

  /// Shared implementation used by both file and string imports.
  static Future<void> _importFromDecodedV2(Map<String, dynamic> decoded) async {
    if (decoded['format'] != _format) {
      throw const FormatException('not a Been Around export file.');
    }

    final version = decoded['version'];
    if (version is! int || version != _version) {
      throw FormatException('unsupported export version ($version).');
    }

    final travelItems = decoded['travel_data_items'];
    if (travelItems is! List) {
      throw const FormatException('missing travel_data_items list.');
    }

    final userItems = decoded['user_data_items'];
    if (userItems is! List) {
      throw const FormatException('missing user_data_items list.');
    }

    final sp = await SharedPreferences.getInstance();

    // Wipe everything first (import becomes the single source of truth)
    await sp.clear();

    // 1) Restore user_data_items
    for (final item in userItems) {
      if (item is! Map) continue;

      final key = item['key'];
      final type = item['type'];
      final value = item['value'];

      if (key is! String || key.isEmpty) continue;
      if (type is! String || type.isEmpty) continue;

      try {
        switch (type) {
          case 'string':
            if (value is String) await sp.setString(key, value);
            break;
          case 'int':
            if (value is int) await sp.setInt(key, value);
            break;
          case 'double':
            if (value is num) await sp.setDouble(key, value.toDouble());
            break;
          case 'bool':
            if (value is bool) await sp.setBool(key, value);
            break;
          case 'stringList':
            if (value is List) {
              final list = value.map((e) => e.toString()).toList();
              await sp.setStringList(key, list);
            }
            break;
          default:
          // unknown type — ignore
            break;
        }
      } catch (_) {
        // ignore broken entry
      }
    }

    // 2) Restore travel_data_items via LocalStore (ensures correct internal formats)
    await _importTravelDataItemsV2(travelItems);
  }

  static Future<void> _importTravelDataItemsV2(List travelItems) async {
    // Overwrite travel data
    await LocalStore.clearSelectionData();

    Map<String, dynamic>? getItemValue(String wantedKey) {
      for (final it in travelItems) {
        if (it is Map && it['key'] == wantedKey) {
          final v = it['value'];
          if (v is Map<String, dynamic>) return v;
          if (v is Map) return Map<String, dynamic>.from(v);
          return null;
        }
      }
      return null;
    }

    // citiesByCountry: Map<String, List<String>>
    final citiesRaw = getItemValue('citiesByCountry');
    if (citiesRaw != null) {
      final out = <String, List<String>>{};
      for (final e in citiesRaw.entries) {
        final iso2 = e.key.toString();
        final v = e.value;
        if (v is List) {
          out[iso2] = v.map((x) => x.toString()).toList();
        }
      }
      await LocalStore.saveCitiesByCountry(out);
    }

    // cityNotes: Map<String, Map<String, String>>
    final notesRaw = getItemValue('cityNotes');
    if (notesRaw != null) {
      final out = <String, Map<String, String>>{};
      for (final e in notesRaw.entries) {
        final iso2 = e.key.toString();
        final v = e.value;
        if (v is Map) {
          out[iso2] = v.map((k, val) => MapEntry(k.toString(), val.toString()));
        }
      }
      await LocalStore.saveCityNotes(out);
    }

    // cityVisitedOn: Map<String, Map<String, String>>
    final cityVisitedRaw = getItemValue('cityVisitedOn');
    if (cityVisitedRaw != null) {
      final out = <String, Map<String, String>>{};
      for (final e in cityVisitedRaw.entries) {
        final iso2 = e.key.toString();
        final v = e.value;
        if (v is Map) {
          out[iso2] = v.map((k, val) => MapEntry(k.toString(), val.toString()));
        }
      }
      await LocalStore.saveCityVisitedOn(out);
    }

    // countryVisitedOn: Map<String, String>
    final countryVisitedRaw = getItemValue('countryVisitedOn');
    if (countryVisitedRaw != null) {
      final out = <String, String>{};
      for (final e in countryVisitedRaw.entries) {
        out[e.key.toString()] = e.value.toString();
      }
      await LocalStore.saveCountryVisitedOn(out);
    }

    // selectedCountries: object map ISO2 -> {name, continent}
    // LocalStore wants only ISO2 set.
    final selectedRaw = getItemValue('selectedCountries');
    if (selectedRaw != null) {
      final iso2s = selectedRaw.keys.map((k) => k.toString()).toSet();
      await LocalStore.saveSelectedCountries(iso2s);
    }
  }
}