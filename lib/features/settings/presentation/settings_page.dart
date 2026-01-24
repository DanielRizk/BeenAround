import 'package:flutter/material.dart';
import '../../../shared/i18n/app_strings.dart';
import 'account_page.dart';
import 'appearance_page.dart';
import 'language_page.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onResetAll});

  final Future<void> Function() onResetAll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_title'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(S.t(context, 'reset_app_data')),
              subtitle: Text(S.t(context, 'reset_app_data_subtitle')),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(S.t(context, 'reset_everything')),
                    content: Text(
                      S.t(context, 'reset_everything_confirm'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(S.t(context, 'cancel')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(S.t(context, 'reset')),
                      ),
                    ],
                  ),
                );

                if (ok != true) return;

                await onResetAll();

                // ✅ clear in-memory (so UI updates immediately)
                // If you want this in SettingsPage, you need access to the notifiers.
                // Easiest: do it in HomeShell (Option B below), or pass callbacks.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.t(context, 'reset_confirmation'))),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}
