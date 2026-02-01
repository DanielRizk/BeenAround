import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

/// Debug helper to export/import *all* SharedPreferences keys.
/// This covers:
/// - selected countries
/// - cities by country
/// - visited dates
/// - notes/memos
/// - app settings (language/theme/whatever you store in prefs)
///
/// Export format is versioned and type-safe:
/// {
///   "format": "been_around_user_data",
///   "version": 1,
///   "exportedAt": "...",
///   "items": [
///     { "key": "...", "type": "string|int|double|bool|stringList", "value": ... }
///   ]
/// }
class UserDataFileTransfer {
  static const String _format = 'been_around_user_data';
  static const int _version = 1;

  /// Exports all SharedPreferences keys into a JSON file stored in app documents folder.
  /// Returns the created file (so caller can share it or show the path).
  static Future<File> exportToFile() async {
    final sp = await SharedPreferences.getInstance();
    final keys = sp.getKeys().toList()..sort();

    final items = <Map<String, dynamic>>[];

    for (final key in keys) {
      final value = sp.get(key);

      if (value is String) {
        items.add({'key': key, 'type': 'string', 'value': value});
      } else if (value is int) {
        items.add({'key': key, 'type': 'int', 'value': value});
      } else if (value is double) {
        items.add({'key': key, 'type': 'double', 'value': value});
      } else if (value is bool) {
        items.add({'key': key, 'type': 'bool', 'value': value});
      } else if (value is List<String>) {
        items.add({'key': key, 'type': 'stringList', 'value': value});
      } else if (value == null) {
        // ignore null keys
      } else {
        // SharedPreferences supports only the above types; if something appears,
        // we skip to avoid corrupt exports.
      }
    }

    final payload = <String, dynamic>{
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items,
    };

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = await getApplicationDocumentsDirectory();

    final now = DateTime.now();
    final ts =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final file = File('${dir.path}/been_around_export_$ts.beenaround.json');
    await file.writeAsString(jsonText, flush: true);
    return file;
  }

  /// Shares an export file via native share sheet (Telegram/Drive/Email/etc.)
  static Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Been Around — user data export',
      subject: 'Been Around user data export',
    );
  }

  /// Lets the user pick an export file, then imports it:
  /// - validates format/version
  /// - clears SharedPreferences
  /// - restores all keys
  ///
  /// Returns a short message suitable for a SnackBar.
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

    final file = File(path);
    if (!await file.exists()) {
      return 'Import failed: file does not exist.';
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      return 'Import failed: invalid JSON format.';
    }

    if (decoded['format'] != _format) {
      return 'Import failed: not a Been Around export file.';
    }

    final version = decoded['version'];
    if (version is! int || version != _version) {
      return 'Import failed: unsupported export version ($version).';
    }

    final items = decoded['items'];
    if (items is! List) {
      return 'Import failed: missing items list.';
    }

    final sp = await SharedPreferences.getInstance();

    // Wipe everything first (so the import becomes the single source of truth)
    await sp.clear();

    for (final item in items) {
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
        // ignore a broken entry instead of failing the entire import
      }
    }

    return 'Import done. Please fully restart the app to reload data.';
  }
}
