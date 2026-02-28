import 'package:flutter/material.dart';

import '../../../shared/export/user_data_file_transfer.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/notifications/local_notification_service.dart';
import '../../../shared/settings/app_settings.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_toast.dart';

class DeveloperModePage extends StatelessWidget {
  const DeveloperModePage({super.key});

  Future<void> _exportUserDataSaveAs(BuildContext context) async {
    try {
      final msg = await UserDataFileTransfer.exportToFile();
      if (!context.mounted) return;
      AppToast.show(context, message: msg, tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, message: 'Save failed: $e', tone: AppToastTone.danger);
    }
  }

  Future<void> _importUserData(BuildContext context) async {
    try {
      final msg = await UserDataFileTransfer.importFromPickedFile();
      if (!context.mounted) return;
      AppToast.show(context, message: msg, tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, message: 'Import user data failed: $e', tone: AppToastTone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AppScaffold(
      title: S.t(context, 'dev_mode_title'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Actions / status
          SectionCard(
            title: S.t(context, 'dev_mode_title'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.visibility_off_rounded,
                  title: S.t(context, 'dev_mode_hide'),
                  subtitle: S.t(context, 'dev_mode_disabled'),
                  tone: TileTone.danger,
                  onTap: () {
                    settings.setDevModeEnabled(false);
                    Navigator.of(context).pop();
                    AppToast.show(context, message: S.t(context, 'dev_mode_disabled'), tone: AppToastTone.success);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dev tools
          SectionCard(
            title: S.t(context, 'dev_tools_title'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.save_alt_rounded,
                  title: S.t(context, 'dev_export_title'),
                  subtitle: S.t(context, 'dev_export_sub'),
                  onTap: () => _exportUserDataSaveAs(context),
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.folder_open_rounded,
                  title: S.t(context, 'dev_import_title'),
                  subtitle: S.t(context, 'dev_import_sub'),
                  onTap: () => _importUserData(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Test notification
          SectionCard(
            title: S.t(context, 'dev_test_notification'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.notifications_active_rounded,
                  title: S.t(context, 'dev_test_notification'),
                  subtitle: S.t(context, 'dev_test_notification'),
                  onTap: () async {
                    await LocalNotificationService.showEnteredCountry(
                      iso2: 'IT',
                      countryName: 'Italy',
                    );
                    if (!context.mounted) return;
                    AppToast.show(context, message: S.t(context, 'dev_test_notification'), tone: AppToastTone.success);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}