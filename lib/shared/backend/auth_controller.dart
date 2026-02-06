import 'dart:typed_data';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/app_settings.dart';
import '../storage/local_store.dart';
import 'api_client.dart';
import 'sync_outbox.dart';

class AuthUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final bool hasProfilePic;

  AuthUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.hasProfilePic,
  });

  String get displayName {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return name.isEmpty ? username : name;
  }

  factory AuthUser.fromJson(Map<String, dynamic> j) {
    return AuthUser(
      id: j['id']?.toString() ?? '',
      username: j['username']?.toString() ?? '',
      firstName: j['first_name']?.toString() ?? '',
      lastName: j['last_name']?.toString() ?? '',
      hasProfilePic: (j['has_profile_pic'] as bool?) ?? false,
    );
  }
}

class AuthController extends ChangeNotifier {
  AuthController({required this.settings}) {
    _api = ApiClient(getAccessToken: _loadToken);
  }

  static const _secure = FlutterSecureStorage();
  static const _kToken = 'auth.jwt';
  static const _kServerRev = 'sync.serverRev';

  final AppSettingsController settings;

  late final ApiClient _api;

  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;

  bool _loading = false;
  bool get isBusy => _loading;

  Timer? _pushDebounce;

  Future<String?> _loadToken() async {
    return _secure.read(key: _kToken);
  }

  Future<void> init() async {
    final token = await _loadToken();
    if (token == null || token.isEmpty) {
      _user = null;
      notifyListeners();
      return;
    }
    try {
      final me = await _api.dio.get('/users/me');
      _user = AuthUser.fromJson(Map<String, dynamic>.from(me.data as Map));

      // Best-effort: flush any queued snapshot.
      unawaited(flushOutbox());
    } catch (_) {
      await _secure.delete(key: _kToken);
      _user = null;
    }
    notifyListeners();
  }

  Future<void> login({required String username, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      final token = (res.data as Map)['access_token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Invalid token from server');
      }
      await _secure.write(key: _kToken, value: token);

      final me = await _api.dio.get('/users/me');
      _user = AuthUser.fromJson(Map<String, dynamic>.from(me.data as Map));

      // Your rule: overwrite local from server snapshot.
      await pullAndApplySnapshot();

      // After we have a good server rev, flush any queued local changes.
      unawaited(flushOutbox());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    required bool migrateGuestData,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      Map<String, dynamic>? initialSnapshot;
      if (migrateGuestData) {
        initialSnapshot = await _buildFullSnapshot();
      }

      final res = await _api.dio.post(
        '/auth/register',
        data: {
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
          'schema_version': AppSettingsController.snapshotSchemaVersion,
          'initial_snapshot': initialSnapshot,
        },
      );

      final token = (res.data as Map)['access_token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Invalid token from server');
      }
      await _secure.write(key: _kToken, value: token);

      final me = await _api.dio.get('/users/me');
      _user = AuthUser.fromJson(Map<String, dynamic>.from(me.data as Map));

      if (migrateGuestData) {
        await pushSnapshot();
      } else {
        await pullAndApplySnapshot();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _secure.delete(key: _kToken);
    _user = null;

    // Your rule: logout clears local travel data.
    await LocalStore.clearSelectionData();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kServerRev);

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (!isLoggedIn) return;
    await _api.dio.delete('/users/me');
    await logout();
  }

  // -------- Profile picture --------

  Future<Uint8List?> downloadProfilePic() async {
    if (!isLoggedIn) return null;
    try {
      final res = await _api.dio.get<List<int>>(
        '/users/me/profile-pic',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null) return null;
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> uploadProfilePicBytes(Uint8List bytes, {String filename = 'profile.jpg'}) async {
    if (!isLoggedIn) return;

    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    await _api.dio.put('/users/me/profile-pic', data: form);

    final me = await _api.dio.get('/users/me');
    _user = AuthUser.fromJson(Map<String, dynamic>.from(me.data as Map));
    notifyListeners();
  }

  Future<void> deleteProfilePic() async {
    if (!isLoggedIn) return;
    try {
      await _api.dio.delete('/users/me/profile-pic');
    } on DioException catch (e) {
      // If server endpoint doesn't exist yet, just don't crash the UI.
      if (e.response?.statusCode != 404) rethrow;
    }

    final me = await _api.dio.get('/users/me');
    _user = AuthUser.fromJson(Map<String, dynamic>.from(me.data as Map));
    notifyListeners();
  }

  // -------- Snapshot sync + outbox --------

  Future<int> _getServerRev() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kServerRev) ?? 0;
  }

  Future<void> _setServerRev(int rev) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kServerRev, rev);
  }

  Future<Map<String, dynamic>> _buildFullSnapshot() async {
    final travel = await LocalStore.exportToJson();
    final appSettings = settings.exportToJson();
    return {
      'schemaVersion': AppSettingsController.snapshotSchemaVersion,
      'travel': travel,
      'settings': appSettings,
    };
  }

  Future<void> pullAndApplySnapshot() async {
    if (!isLoggedIn) return;
    final res = await _api.dio.get('/sync/snapshot');
    final data = Map<String, dynamic>.from(res.data as Map);
    final rev = (data['rev'] as int?) ?? int.parse(data['rev'].toString());
    final snap = Map<String, dynamic>.from(data['snapshot'] as Map);
    await _setServerRev(rev);

    final travel = (snap['travel'] as Map?) ?? const {};
    final settingsJson = (snap['settings'] as Map?) ?? const {};

    await LocalStore.importFromJson(Map<String, dynamic>.from(travel));
    await settings.importFromJson(Map<String, dynamic>.from(settingsJson));
  }

  /// Call this whenever local data changes and you want cloud backup.
  ///
  /// - If online: pushes after a short debounce.
  /// - If offline/server down: stores a single "latest" snapshot in the outbox.
  void scheduleBackup() {
    if (!isLoggedIn) return;

    _pushDebounce?.cancel();
    _pushDebounce = Timer(const Duration(milliseconds: 1500), () {
      unawaited(_backupNow());
    });
  }

  Future<void> _backupNow() async {
    if (!isLoggedIn) return;
    final baseRev = await _getServerRev();
    final snapshot = await _buildFullSnapshot();
    try {
      await _pushSnapshotInternal(baseRev: baseRev, snapshot: snapshot);
      await SyncOutbox.clear();
    } on DioException catch (e) {
      if (e.response == null) {
        await SyncOutbox.put(baseRev: baseRev, snapshot: snapshot);
        return;
      }
      rethrow;
    }
  }

  Future<void> flushOutbox() async {
    if (!isLoggedIn) return;
    final item = await SyncOutbox.get();
    if (item == null) return;

    try {
      await _pushSnapshotInternal(baseRev: item.baseRev, snapshot: item.snapshot);
      await SyncOutbox.clear();
    } on DioException catch (e) {
      if (e.response == null) {
        return; // still offline
      }
      rethrow;
    }
  }

  Future<void> pushSnapshot() async {
    if (!isLoggedIn) return;

    final baseRev = await _getServerRev();
    final snapshot = await _buildFullSnapshot();

    await _pushSnapshotInternal(baseRev: baseRev, snapshot: snapshot);
  }

  Future<void> _pushSnapshotInternal({required int baseRev, required Map<String, dynamic> snapshot}) async {
    try {
      final res = await _api.dio.put(
        '/sync/snapshot',
        data: {
          'schema_version': AppSettingsController.snapshotSchemaVersion,
          'base_rev': baseRev,
          'snapshot': snapshot,
          'device_id': null,
          'client_ts_ms': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final newRev = (data['rev'] as int?) ?? int.parse(data['rev'].toString());
      await _setServerRev(newRev);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Your rule: overwrite local from server
        await pullAndApplySnapshot();
        await SyncOutbox.clear();
        return;
      }
      rethrow;
    }
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found in context');
    return scope!.notifier!;
  }
}
