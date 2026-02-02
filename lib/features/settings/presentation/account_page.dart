import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../shared/export/travel_pdf_exporter.dart';
import '../../../shared/export/world_map_image_renderer.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../../shared/settings/app_settings.dart';
import '../../../shared/storage/local_store.dart';

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

      final settings = AppSettingsScope.of(context);
      final lightScheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
      ).colorScheme;

      final borderColor = lightScheme.outlineVariant.withAlpha(180);


      final selectedIds = await LocalStore.loadSelectedCountries();

      final mapPng = await WorldMapImageRenderer.renderPng(
        map: worldMapData,
        selectedIds: selectedIds,
        selectedColor: settings.selectedCountryColor,
        multicolor: settings.selectedCountryColorMode ==
            SelectedCountryColorMode.multicolor,
        palette: AppSettingsController.countryColorPalette,
        borderColor: borderColor,
        pixelSize: const Size(2400, 1200),
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
        SnackBar(content: Text('${S.t(context, 'export_failed')} $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_account'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SizedBox(height: 8),

          // Existing PDF export
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(S.t(context, 'export_travel_data')),
            subtitle: Text(S.t(context, 'export_travel_data_sub')),
            onTap: () => _exportTravelPdf(context),
          ),

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
              title: Text(S.t(context, 'export_options')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.t(context, 'export_option_msg'),),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: includeMemos,
                    onChanged: (v) => setState(() {
                      includeMemos = v ?? true;
                    }),
                    title: Text(S.t(context, 'include_notes')),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(S.t(context, 'cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(includeMemos),
                  child: Text(S.t(context, 'export')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
