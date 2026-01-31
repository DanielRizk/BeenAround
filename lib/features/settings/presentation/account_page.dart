import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../../shared/export/travel_pdf_exporter.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.worldMapData});

  final WorldMapData worldMapData;

  Future<void> _exportTravelPdf(BuildContext context) async {
    // Temporary / MVP flow:
    const appName = 'Been Around';
    const displayName = 'Me';

    try {
      final pdfBytes = await TravelPdfExporter.buildPdf(
        map: worldMapData,
        appName: appName,
        displayName: displayName,
        // Change this if your logo asset is different:
        logoAssetPath: TravelPdfExporter.defaultLogoAssetPath,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_account'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export travel data'),
            subtitle: const Text('Generate a PDF with visited countries & cities.'),
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
}
