import 'package:been_around/shared/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = AppSettingsController();
  await settings.load(); // ✅ load persisted preferences

  runApp(BeenAroundApp(settings: settings));
}
