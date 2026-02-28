import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../../shared/settings/app_settings.dart';

import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_dialogs.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_toast.dart';

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

  // ✅ Change this to whatever 6 digits you want
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

    final code = await AppDialogs.showSixDigitCodeDialog(
      context: context,
      title: S.t(context, 'dev_mode_enable_title'),
      subtitle: S.t(context, 'dev_mode_enable_msg'),
      confirmLabel: S.t(context, 'enable'),
      cancelLabel: S.t(context, 'cancel'),
      defaultErrorMessage: S.t(context, 'dev_mode_pin_wrong'),
      validate: (input) async {
        return input.trim() == _kDevPin ? null : S.t(context, 'dev_mode_pin_wrong');
      },
    );

    if (!mounted) return;
    if (code == null) return;

    // enable dev mode
    Future.microtask(() => settings.setDevModeEnabled(true));

    AppToast.show(
      context,
      message: S.t(context, 'dev_mode_enabled'),
      tone: AppToastTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AppScaffold(
      title: S.t(context, 'settings_title'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          SectionCard(
            title: S.t(context, 'settings_account'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.person_outline,
                  title: S.t(context, 'settings_account'),
                  subtitle: S.t(context, 'settings_account_sub'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountPage(
                          worldMapData: widget.worldMapData,
                          onResetAll: widget.onResetAll,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: S.t(context, 'settings_appearance'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.palette_outlined,
                  title: S.t(context, 'settings_appearance'),
                  subtitle: S.t(context, 'settings_appearance_sub'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppearancePage()),
                    );
                  },
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.language_outlined,
                  title: S.t(context, 'settings_language'),
                  subtitle: S.t(context, 'lang_${S.lang(context).name}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguagePage()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: S.t(context, 'settings_privacy'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.lock_outline,
                  title: S.t(context, 'settings_privacy'),
                  subtitle: S.t(context, 'settings_privacy_sub'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    );
                  },
                ),
                if (settings.devModeEnabled) ...[
                  const SoftDivider(),
                  MotionTile(
                    icon: Icons.developer_mode,
                    title: S.t(context, 'dev_mode_title'),
                    subtitle: S.t(context, 'dev_mode_sub'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DeveloperModePage()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: S.t(context, 'reset_app_data'),
            tone: CardTone.danger,
            child: Column(
              children: [
                Listener(
                  // ✅ hidden dev hold remains (no UI)
                  onPointerDown: (_) => _startDevHold(),
                  onPointerUp: (_) => _cancelDevHold(),
                  onPointerCancel: (_) => _cancelDevHold(),
                  child: MotionTile(
                    icon: Icons.delete_forever_outlined,
                    title: S.t(context, 'reset_app_data'),
                    subtitle: S.t(context, 'reset_app_data_subtitle'),
                    tone: TileTone.danger,
                    onTap: () async {
                      final ok = await AppDialogs.showConfirmDialog(
                        context: context,
                        title: S.t(context, 'reset_everything'),
                        message: S.t(context, 'reset_everything_confirm'),
                        cancelLabel: S.t(context, 'cancel'),
                        confirmLabel: S.t(context, 'reset'),
                        tone: AppDialogTone.danger,
                      );

                      if (!ok) return;

                      await widget.onResetAll();
                      if (!mounted) return;

                      AppToast.show(
                        context,
                        message: S.t(context, 'reset_confirmation'),
                        tone: AppToastTone.success,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}