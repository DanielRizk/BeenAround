import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Very small offline outbox.
///
/// We only keep the latest snapshot push (dedupe), because the server
/// API is snapshot-based anyway.
class SyncOutbox {
  static const _kOutbox = 'sync.outbox.latest';

  static Future<void> put({required int baseRev, required Map<String, dynamic> snapshot}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kOutbox,
      jsonEncode({
        'baseRev': baseRev,
        'snapshot': snapshot,
      }),
    );
  }

  static Future<({int baseRev, Map<String, dynamic> snapshot})?> get() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kOutbox);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final baseRev = decoded['baseRev'];
    final snap = decoded['snapshot'];
    final baseRevInt = baseRev is int ? baseRev : int.tryParse(baseRev?.toString() ?? '') ?? 0;
    final snapshot = snap is Map ? Map<String, dynamic>.from(snap) : <String, dynamic>{};
    return (baseRev: baseRevInt, snapshot: snapshot);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kOutbox);
  }
}
