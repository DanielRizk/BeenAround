import 'package:flutter/material.dart';
import '../../../shared/i18n/app_strings.dart';
import 'account_page.dart';
import 'appearance_page.dart';
import 'language_page.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_title'))),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(S.t(context, 'settings_account')),
            subtitle: Text(S.t(context, 'settings_account_sub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountPage()),
              );
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(S.t(context, 'settings_appearance')),
            subtitle: Text(S.t(context, 'settings_appearance_sub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppearancePage()),
              );
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(S.t(context, 'settings_language')),
            subtitle: Text(S.t(context, 'lang_${S.lang(context).name}')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguagePage()),
              );
            },
          ),
          const Divider(height: 1),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
