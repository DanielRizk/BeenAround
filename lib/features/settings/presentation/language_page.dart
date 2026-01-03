import 'package:flutter/material.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/settings/app_settings.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_language'))),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final code = settings.locale.languageCode;

          return ListView(
            children: [
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'en',
                groupValue: code,
                title: Text(S.t(context, 'lang_en')),
                onChanged: (_) => settings.setLocale(const Locale('en')),
              ),
              RadioListTile<String>(
                value: 'de',
                groupValue: code,
                title: Text(S.t(context, 'lang_de')),
                onChanged: (_) => settings.setLocale(const Locale('de')),
              ),
            ],
          );
        },
      ),
    );
  }
}
