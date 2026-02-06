import 'package:been_around/shared/backend/auth_controller.dart';
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

  final auth = AuthController(settings: settings);
  await auth.init();

  // When settings change and user is logged in -> schedule cloud backup.
  settings.addListener(() {
    auth.scheduleBackup();
  });

  runApp(BeenAroundApp(settings: settings, auth: auth,));

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
