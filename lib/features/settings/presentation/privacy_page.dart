import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/settings/app_settings.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _busyNotif = false;
  bool _busyLoc = false;
  bool _busyDetect = false;

  AppSettingsController get _settings => AppSettingsScope.of(context);

  Future<void> _showMsg(String text) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _ensureNotificationsEnabled() async {
    setState(() => _busyNotif = true);
    try {
      final plugin = FlutterLocalNotificationsPlugin();

      // ANDROID (13+)
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        // Request permission (Android 13+)
        await android.requestNotificationsPermission();

        final enabled = await android.areNotificationsEnabled();
        if (enabled == false) {
          await _showMsg(S.t(context, 'privacy_notifications_denied'));
          await Geolocator.openAppSettings();
          return false;
        }
        return true;
      }

      // IOS / MACOS
      // No reliable "check enabled" API → just request
      final granted = await plugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (granted == false) {
        await _showMsg(S.t(context, 'privacy_notifications_denied'));
        await Geolocator.openAppSettings();
        return false;
      }

      return true;
    } finally {
      if (mounted) setState(() => _busyNotif = false);
    }
  }


  Future<bool> _ensureLocationEnabled() async {
    setState(() => _busyLoc = true);
    try {
      // 1) services enabled?
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await _showMsg(S.t(context, 'privacy_location_services_off'));
        await Geolocator.openLocationSettings();
        final enabled2 = await Geolocator.isLocationServiceEnabled();
        if (!enabled2) return false;
      }

      // 2) permission granted?
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await _showMsg(S.t(context, 'privacy_location_denied'));
        await Geolocator.openAppSettings();
        return false;
      }

      return true;
    } finally {
      if (mounted) setState(() => _busyLoc = false);
    }
  }

  Future<void> _toggleNotifications(bool v) async {
    if (!v) {
      _settings.setPrivacyNotifications(false);

      // If notifications off => detection must stop
      _settings.setPrivacyCountryDetection(false);
      return;
    }

    final ok = await _ensureNotificationsEnabled();
    if (!ok) {
      _settings.setPrivacyNotifications(false);
      return;
    }

    _settings.setPrivacyNotifications(true);
  }

  Future<void> _toggleLocation(bool v) async {
    if (!v) {
      _settings.setPrivacyLocation(false);

      // If location off => detection must stop
      _settings.setPrivacyCountryDetection(false);
      return;
    }

    final ok = await _ensureLocationEnabled();
    if (!ok) {
      _settings.setPrivacyLocation(false);
      return;
    }

    _settings.setPrivacyLocation(true);
  }

  Future<void> _toggleDetection(bool v) async {
    setState(() => _busyDetect = true);
    try {
      if (!v) {
        _settings.setPrivacyCountryDetection(false);
        return;
      }

      // Detection requires both
      if (!_settings.privacyNotifications) {
        final ok = await _ensureNotificationsEnabled();
        if (!ok) {
          _settings.setPrivacyCountryDetection(false);
          return;
        }
        _settings.setPrivacyNotifications(true);
      }

      if (!_settings.privacyLocation) {
        final ok = await _ensureLocationEnabled();
        if (!ok) {
          _settings.setPrivacyCountryDetection(false);
          return;
        }
        _settings.setPrivacyLocation(true);
      }

      _settings.setPrivacyCountryDetection(true);
      await _showMsg(S.t(context, 'privacy_detection_enabled'));
    } finally {
      if (mounted) setState(() => _busyDetect = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'privacy_title'))),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(S.t(context, 'privacy_notifications')),
            subtitle: Text(S.t(context, 'privacy_notifications_sub')),
            value: s.privacyNotifications,
            onChanged: _busyNotif ? null : _toggleNotifications,
          ),
          const Divider(height: 1),

          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined),
            title: Text(S.t(context, 'privacy_location')),
            subtitle: Text(S.t(context, 'privacy_location_sub')),
            value: s.privacyLocation,
            onChanged: _busyLoc ? null : _toggleLocation,
          ),
          const Divider(height: 1),

          SwitchListTile(
            secondary: const Icon(Icons.public_outlined),
            title: Text(S.t(context, 'privacy_detection')),
            subtitle: Text(S.t(context, 'privacy_detection_sub')),
            value: s.privacyCountryDetection,
            onChanged: _busyDetect ? null : _toggleDetection,
          ),
          const Divider(height: 1),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              S.t(context, 'privacy_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
