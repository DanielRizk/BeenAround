import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../../shared/settings/app_settings.dart';
import 'account_page.dart';
import 'appearance_page.dart';
import 'developer_mode_page.dart';
import 'language_page.dart';
import 'privacy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.onResetAll,
    required this.worldMapData,
  });

  final Future<void> Function() onResetAll;
  final WorldMapData worldMapData;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Timer? _devHoldTimer;
  bool _devHoldActive = false;

  // ✅ Change this to whatever 4 digits you want
  static const String _kDevPin = '268426';

  @override
  void dispose() {
    _devHoldTimer?.cancel();
    super.dispose();
  }

  void _startDevHold() {
    if (_devHoldActive) return;
    _devHoldActive = true;

    _devHoldTimer?.cancel();
    _devHoldTimer = Timer(const Duration(seconds: 5), () {
      _devHoldActive = false;
      _devHoldTimer = null;
      _showDevModePrompt();
    });
  }

  void _cancelDevHold() {
    _devHoldActive = false;
    _devHoldTimer?.cancel();
    _devHoldTimer = null;
  }

  Future<void> _showDevModePrompt() async {
    final settings = AppSettingsScope.of(context);

    if (settings.devModeEnabled) return;

    final pinController = TextEditingController();
    bool wrong = false;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(S.t(context, 'dev_mode_enable_title')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t(context, 'dev_mode_enable_msg')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: S.t(context, 'dev_mode_pin'),
                        errorText: wrong ? S.t(context, 'dev_mode_pin_wrong') : null,
                        counterText: '', // avoids extra height from counter
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(S.t(context, 'cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final pin = pinController.text.trim();
                    if (pin == _kDevPin) {
                      Navigator.pop(ctx, true);
                    } else {
                      setLocal(() => wrong = true);
                    }
                  },
                  child: Text(S.t(context, 'enable')),
                ),
              ],
            );
          },
        );
      },
    );

    // ✅ IMPORTANT: dispose controller AFTER the dialog is fully removed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pinController.dispose();
    });

    if (ok == true) {
      // ✅ Also defer enabling to next microtask (keeps Flutter happy)
      Future.microtask(() {
        settings.setDevModeEnabled(true);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'dev_mode_enabled'))),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_title'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),

                // ✅ Account tile + hidden dev hold (5 seconds)
                Listener(
                  onPointerDown: (_) => _startDevHold(),
                  onPointerUp: (_) => _cancelDevHold(),
                  onPointerCancel: (_) => _cancelDevHold(),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(S.t(context, 'settings_account')),
                    subtitle: Text(S.t(context, 'settings_account_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AccountPage(worldMapData: widget.worldMapData),
                        ),
                      );
                    },
                  ),
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

                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(S.t(context, 'settings_privacy')),
                  subtitle: Text(S.t(context, 'settings_privacy_sub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    );
                  },
                ),

                // ✅ Show Developer Mode only if enabled
                if (settings.devModeEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.developer_mode),
                    title: Text(S.t(context, 'dev_mode_title')),
                    subtitle: Text(S.t(context, 'dev_mode_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DeveloperModePage(),
                        ),
                      );
                    },
                  ),
                ],

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
                    content: Text(S.t(context, 'reset_everything_confirm')),
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

                await widget.onResetAll();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.t(context, 'reset_confirmation'))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
