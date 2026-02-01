import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../map/world_map_models.dart';
import '../storage/local_store.dart';

class TravelPdfExporter {
  static const String defaultLogoAssetPath = 'assets/splash/logo.png';

  // Optional: if you later add fonts, you can re-enable this.
  // static const String _fontRegularPath = 'assets/fonts/NotoSans-Regular.ttf';
  // static const String _fontBoldPath = 'assets/fonts/NotoSans-Bold.ttf';

  static const List<PdfColor> _accentPalette = <PdfColor>[
    PdfColors.blue,
    PdfColors.teal,
    PdfColors.green,
    PdfColors.amber,
    PdfColors.orange,
    PdfColors.pink,
    PdfColors.purple,
    PdfColors.red,
  ];

  static Future<Uint8List> buildPdf({
    required WorldMapData map,
    required String appName,
    required String displayName,
    String logoAssetPath = defaultLogoAssetPath,
    Uint8List? worldMapPngBytes,
    bool includeMemos = true,
  }) async {
    final selectedIds = await LocalStore.loadSelectedCountries();
    final citiesByCountry = await LocalStore.loadCitiesByCountry();
    final countryVisitedOn = await LocalStore.loadCountryVisitedOn();
    final cityVisitedOn = await LocalStore.loadCityVisitedOn();
    final cityNotes = await LocalStore.loadCityNotes();

    final countries = selectedIds
        .map((id) => _CountryRow(
      id: id,
      name: map.nameById[id] ?? _fallbackNameFromMap(map, id) ?? id,
      visitedOnIso: countryVisitedOn[id],
      cities: (citiesByCountry[id] ?? const <String>[]).toList(),
    ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load(logoAssetPath);
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    // If you later add fonts, uncomment and set theme:
    // final fontRegular = pw.Font.ttf(await rootBundle.load(_fontRegularPath));
    // final fontBold = pw.Font.ttf(await rootBundle.load(_fontBoldPath));
    // final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    final doc = pw.Document(version: PdfVersion.pdf_1_4, compress: true);
    final nowIso = DateTime.now().toIso8601String();

    doc.addPage(
      pw.MultiPage(
        // theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 30),
        build: (context) {
          final widgets = <pw.Widget>[
            _buildHeader(
              appName: appName,
              displayName: displayName,
              logo: logo,
              generatedOnIso: nowIso,
              visitedCount: countries.length,
            ),
            pw.SizedBox(height: 16),

            if (worldMapPngBytes != null) ...[
              _buildWorldMapPreview(worldMapPngBytes),
              pw.SizedBox(height: 16),
            ],
          ];

          if (countries.isEmpty) {
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Text(
                  'No travel data yet.',
                  style: pw.TextStyle(fontSize: 13, color: PdfColors.grey800),
                ),
              ),
            );
            return widgets;
          }

          for (final c in countries) {
            final accent =
            _accentPalette[_stableIndex(c.name, _accentPalette.length)];
            final cityVisitedMap =
                cityVisitedOn[c.id] ?? const <String, String>{};
            final cityNotesMap = cityNotes[c.id] ?? const <String, String>{};

            widgets.addAll(
              _buildCountryFlow(
                country: c,
                accent: accent,
                cityVisitedOn: cityVisitedMap,
                cityNotes: cityNotesMap,
                includeMemos: includeMemos,
              ),
            );

            widgets.add(pw.SizedBox(height: 14));
          }

          return widgets;
        },
        footer: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  appName,
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildWorldMapPreview(Uint8List pngBytes) {
    final img = pw.MemoryImage(pngBytes);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'World map',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 8),

          // ✅ CRITICAL: constrain height so MultiPage can paginate safely
          pw.Container(
            height: 350, // tweak: 200..320 depending on how big you want it
            width: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.Image(
              img,
              fit: pw.BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }



  static pw.Widget _buildHeader({
    required String appName,
    required String displayName,
    required pw.ImageProvider? logo,
    required String generatedOnIso,
    required int visitedCount,
  }) {
    final dateText = _formatDate(generatedOnIso);

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.9, color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo box (no radius)
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.9),
            ),
            alignment: pw.Alignment.center,
            child: logo != null
                ? pw.Image(logo, fit: pw.BoxFit.cover)
                : pw.Text(
              appName.isNotEmpty ? appName[0].toUpperCase() : 'B',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Travel Export',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$appName - $displayName',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _tagBox('Generated: $dateText'),
                    pw.SizedBox(width: 6),
                    _tagBox('Visited countries: $visitedCount'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tagBox(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  /// Pagination fix:
  /// - header + first city are one widget => never orphan header
  /// - remaining cities separate => flow naturally
  static List<pw.Widget> _buildCountryFlow({
    required _CountryRow country,
    required PdfColor accent,
    required Map<String, String> cityVisitedOn,
    required Map<String, String> cityNotes,
    required bool includeMemos,
  }) {
    final visitedOn = _formatDate(country.visitedOnIso);
    final cities = country.cities.toList()..sort();

    final header = _countryHeader(
      name: country.name,
      visitedOn: visitedOn.isEmpty ? '—' : visitedOn,
      accent: accent,
    );

    if (cities.isEmpty) {
      return [
        pw.Column(
          children: [
            header,
            _rowBox(
              accent: accent,
              isHeader: false,
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: pw.Text(
                  'No cities saved.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            ),
          ],
        ),
      ];
    }

    pw.Widget cityRow(String city) {
      final cityDate = _formatDate(cityVisitedOn[city]);
      final memo = cityNotes[city]?.trim();

      return _rowBox(
        accent: accent,
        isHeader: false,
        child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '- ',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      city,
                      style: pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
                    ),
                  ),
                  if (cityDate.isNotEmpty)
                    pw.Text(
                      cityDate,
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                ],
              ),
              if (includeMemos && memo != null && memo.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Container(
                  margin: const pw.EdgeInsets.only(left: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                  ),
                  child: pw.Text(
                    memo,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // bundle header + first city in ONE widget to prevent empty header at page end
    final firstBundle = pw.Column(
      children: [
        header,
        cityRow(cities.first),
      ],
    );

    final rest = <pw.Widget>[];
    for (int i = 1; i < cities.length; i++) {
      rest.add(cityRow(cities[i]));
    }

    return [firstBundle, ...rest];
  }

  static pw.Widget _countryHeader({
    required String name,
    required String visitedOn,
    required PdfColor accent,
  }) {
    return _rowBox(
      accent: accent,
      isHeader: true,
      child: pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ),
            pw.Text(
              visitedOn,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  /// Rectangular row boxes only (NO BorderRadius anywhere).
  static pw.Container _rowBox({
    required PdfColor accent,
    required bool isHeader,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColors.grey50 : PdfColors.white,
        border: pw.Border(
          left: pw.BorderSide(color: accent, width: 3.0),
          top: const pw.BorderSide(color: PdfColors.grey300, width: 0.7),
          right: const pw.BorderSide(color: PdfColors.grey300, width: 0.7),
          bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.7),
        ),
      ),
      child: child,
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    } catch (_) {
      return '';
    }
  }

  static int _stableIndex(String s, int mod) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;
    final normalized = s.trim().toLowerCase();
    for (final cu in normalized.codeUnits) {
      hash ^= cu;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return (mod <= 0) ? 0 : (hash % mod);
  }

  static String? _fallbackNameFromMap(WorldMapData map, String id) {
    for (final c in map.countries) {
      if (c.id == id) return c.name;
    }
    return null;
  }
}

class _CountryRow {
  final String id;
  final String name;
  final String? visitedOnIso;
  final List<String> cities;

  const _CountryRow({
    required this.id,
    required this.name,
    required this.visitedOnIso,
    required this.cities,
  });
}
