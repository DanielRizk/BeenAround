import 'package:flutter/foundation.dart';

import '../settings/app_settings.dart';
import 'country_monitor.dart';

class CountryMonitorManager {
  CountryMonitorManager._();

  static final CountryMonitorManager instance = CountryMonitorManager._();

  CountryMonitor? _monitor;
  AppSettingsController? _settings;

  void bind({
    required CountryMonitor monitor,
    required AppSettingsController settings,
  }) {
    _settings?.removeListener(_apply);
    
    _monitor = monitor;
    _settings = settings;

    // Re-apply whenever user changes privacy toggles
    settings.addListener(_apply);
    _apply();
  }

  Future<void> _apply() async {
    final m = _monitor;
    final s = _settings;
    if (m == null || s == null) return;

    final shouldRun =
        s.privacyCountryDetection && s.privacyLocation && s.privacyNotifications;

    if (shouldRun) {
      if (kDebugMode) debugPrint('[CountryMonitorManager] start monitor');
      await m.start();
    } else {
      if (kDebugMode) debugPrint('[CountryMonitorManager] stop monitor');
      await m.stop();
    }
  }
}
