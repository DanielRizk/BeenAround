import 'package:been_around/shared/export/user_data_file_transfer.dart';
import 'package:been_around/shared/location/country_monitor.dart';
import 'package:been_around/shared/location/country_monitor_manager.dart';
import 'package:been_around/shared/notifications/local_notification_service.dart';
import 'package:been_around/shared/settings/app_settings.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';

final CountryMonitor countryMonitor =
CountryMonitor(cooldown: const Duration(hours: 12));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialPayload = await LocalNotificationService.init(
    onTap: (payload) => BeenAroundApp.handleNotificationPayload(payload),
  );

  final settings = AppSettingsController();
  await settings.load();

  UserDataFileTransfer.onImportApplied = () async {
    // refresh settings (theme/locale/colors/etc)
    await settings.load();

    // refresh travel data (your HomeShell notifiers)
    await BeenAroundApp.homeKey.currentState?.reloadAllFromStorage();
  };

  runApp(BeenAroundApp(settings: settings));

  // ✅ Bind manager (it will start/stop monitor depending on privacy toggles)
  CountryMonitorManager.instance.bind(
    monitor: countryMonitor,
    settings: settings,
  );

  // If app was launched by tapping notification, handle after first frame
  if (initialPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BeenAroundApp.handleNotificationPayload(initialPayload);
    });
  }
}
