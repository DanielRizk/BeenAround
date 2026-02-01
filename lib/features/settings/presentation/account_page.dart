import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../shared/export/travel_pdf_exporter.dart';
import '../../../shared/export/user_data_file_transfer.dart';
import '../../../shared/export/user_data_saf_save.dart';
import '../../../shared/export/widget_capture.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../map/presentation/map_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.worldMapData});

  final WorldMapData worldMapData;

  Future<void> _exportTravelPdf(BuildContext context) async {
    // Temporary / MVP flow:
    const appName = 'Been Around';
    const displayName = 'Me';

    try {
      final includeMemos = await _askIncludeMemos(context);
      if (includeMemos == null) return; // user canceled

      final mapPng = await captureRepaintBoundary(
        MapPage.mapRepaintKey,
      );

      final pdfBytes = await TravelPdfExporter.buildPdf(
        map: worldMapData,
        appName: appName,
        displayName: displayName,
        // Change this if your logo asset is different:
        logoAssetPath: TravelPdfExporter.defaultLogoAssetPath,
        worldMapPngBytes: mapPng,
        includeMemos: includeMemos,
      );

      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'TravelData_$y-$m-$d.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

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
    bool _debug = false;
    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_account'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SizedBox(height: 8),

          // Existing PDF export
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export travel data'),
            subtitle: const Text('Generate a PDF with visited countries & cities.'),
            onTap: () => _exportTravelPdf(context),
          ),

          // Debug-only: export/import full user data file
          if (_debug) ...[
            const Divider(height: 24),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Debug tools',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Export user data (file)'),
              subtitle: const Text('Export all settings, countries, cities, dates, notes…'),
              onTap: () => _exportUserDataSaveAs(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Import user data (file)'),
              subtitle: const Text('Load export file and replace current local data.'),
              onTap: () => _importUserData(context),
            ),
          ],

          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Account page (placeholder)\n\nLater: login, sync, cloud backup, etc.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _askIncludeMemos(BuildContext context) async {
    bool includeMemos = true;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Export options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose what to include in the PDF:',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: includeMemos,
                    onChanged: (v) => setState(() {
                      includeMemos = v ?? true;
                    }),
                    title: const Text('Include notes'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(includeMemos),
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
