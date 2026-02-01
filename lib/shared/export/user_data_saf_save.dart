import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataSafSave {
  static const _channel = MethodChannel('been_around/saf_save');

  static const String _format = 'been_around_user_data';
  static const int _version = 1;

  /// Builds the JSON export in-memory and asks Android “Save as…” where the user chooses location.
  static Future<String> saveAsDocument() async {
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
      }
    }

    final payload = <String, dynamic>{
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items,
    };

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);

    // Ask Android to show a “Save as…” UI and write the contents to the chosen URI.
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
}
