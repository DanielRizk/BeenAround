import 'package:been_around/shared/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  final settings = AppSettingsController();
  runApp(BeenAroundApp(settings: settings));
}
