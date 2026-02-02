import 'package:flutter/material.dart';

import '../../../shared/export/user_data_file_transfer.dart';
import '../../../shared/export/user_data_saf_save.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/notifications/local_notification_service.dart';
import '../../../shared/settings/app_settings.dart';

class DeveloperModePage extends StatelessWidget {
  const DeveloperModePage({super.key});

  Future<void> _exportUserDataSaveAs(BuildContext context) async {
    try {
      final msg = await UserDataSafSave.saveAsDocument();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _importUserData(BuildContext context) async {
    try {
      final msg = await UserDataFileTransfer.importFromPickedFile();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import user data failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t(context, 'dev_mode_title')),
        actions: [
          TextButton.icon(
            onPressed: () {
              settings.setDevModeEnabled(false);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.t(context, 'dev_mode_disabled'))),
              );
            },
            icon: const Icon(Icons.visibility_off),
            label: Text(S.t(context, 'dev_mode_hide')),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              S.t(context, 'dev_tools_title'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(S.t(context, 'dev_export_title')),
            subtitle: Text(S.t(context, 'dev_export_sub')),
            onTap: () => _exportUserDataSaveAs(context),
          ),

          ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text(S.t(context, 'dev_import_title')),
            subtitle: Text(S.t(context, 'dev_import_sub')),
            onTap: () => _importUserData(context),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                await LocalNotificationService.showEnteredCountry(
                  iso2: 'IT',
                  countryName: 'Italy',
                );
              },
              child: Text(S.t(context, 'dev_test_notification')),
            ),
          ),
        ],
      ),
    );
  }
}
