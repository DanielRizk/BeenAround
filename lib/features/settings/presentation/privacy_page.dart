import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/settings/app_settings.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_style.dart';
import '../../../shared/ui_kit/app_toast.dart';

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

  Future<void> _showMsg(String text, {AppToastTone tone = AppToastTone.normal}) async {
    if (!mounted) return;
    AppToast.show(context, message: text, tone: tone);
  }

  Future<bool> _ensureNotificationsEnabled() async {
    setState(() => _busyNotif = true);
    try {
      final plugin = FlutterLocalNotificationsPlugin();

      // ANDROID (13+)
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        await android.requestNotificationsPermission();

        final enabled = await android.areNotificationsEnabled();
        if (enabled == false) {
          await _showMsg(S.t(context, 'privacy_notifications_denied'), tone: AppToastTone.danger);
          await Geolocator.openAppSettings();
          return false;
        }
        return true;
      }

      // IOS / MACOS
      final granted = await plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (granted == false) {
        await _showMsg(S.t(context, 'privacy_notifications_denied'), tone: AppToastTone.danger);
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
        await _showMsg(S.t(context, 'privacy_location_services_off'), tone: AppToastTone.danger);
        await Geolocator.openLocationSettings();
        final enabled2 = await Geolocator.isLocationServiceEnabled();
        if (!enabled2) return false;
      }

      // 2) permission granted?
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        await _showMsg(S.t(context, 'privacy_location_denied'), tone: AppToastTone.danger);
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
      await _showMsg(S.t(context, 'privacy_detection_enabled'), tone: AppToastTone.success);
    } finally {
      if (mounted) setState(() => _busyDetect = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;

    return AppScaffold(
      title: S.t(context, 'privacy_title'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            title: S.t(context, 'privacy_title'),
            child: Column(
              children: [
                _SwitchMotionTile(
                  icon: Icons.notifications_outlined,
                  title: S.t(context, 'privacy_notifications'),
                  subtitle: S.t(context, 'privacy_notifications_sub'),
                  value: s.privacyNotifications,
                  busy: _busyNotif,
                  onChanged: _toggleNotifications,
                ),
                const SoftDivider(),
                _SwitchMotionTile(
                  icon: Icons.location_on_outlined,
                  title: S.t(context, 'privacy_location'),
                  subtitle: S.t(context, 'privacy_location_sub'),
                  value: s.privacyLocation,
                  busy: _busyLoc,
                  onChanged: _toggleLocation,
                ),
                const SoftDivider(),
                _SwitchMotionTile(
                  icon: Icons.public_outlined,
                  title: S.t(context, 'privacy_detection'),
                  subtitle: S.t(context, 'privacy_detection_sub'),
                  value: s.privacyCountryDetection,
                  busy: _busyDetect,
                  onChanged: _toggleDetection,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              S.t(context, 'privacy_hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ UI-kit-consistent switch row:
/// - same motion feel as MotionTile
/// - no ListTile / SwitchListTile legacy visuals
/// - switch is the only interactive control (tap anywhere toggles)
class _SwitchMotionTile extends StatefulWidget {
  const _SwitchMotionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.busy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchMotionTile> createState() => _SwitchMotionTileState();
}

class _SwitchMotionTileState extends State<_SwitchMotionTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final disabled = widget.busy;
    final accent = cs.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: disabled ? null : () => widget.onChanged(!widget.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: _down ? accent.withOpacity(.06) : Colors.transparent,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(style.iconRadius),
                color: accent.withOpacity(_down ? .16 : .10),
              ),
              child: Icon(widget.icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: disabled ? .60 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IgnorePointer(
              ignoring: disabled,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: disabled ? .6 : 1.0,
                child: Switch(
                  value: widget.value,
                  onChanged: disabled ? null : widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}