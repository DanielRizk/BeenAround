import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/i18n/app_strings.dart';
import 'country_cities_page.dart';
import 'widgets/gradient_gauge.dart';

class ContinentCountriesPage extends StatelessWidget {
  final String continent;
  final List<String> iso2s;

  final Set<String> visitedCountryIds;
  final Map<String, List<String>> citiesByCountry; // visited cities
  final Map<String, String> countryNameById; // iso2 -> name (if available)
  final Map<String, List<String>> iso2ToCities; // all cities

  const ContinentCountriesPage({
    super.key,
    required this.continent,
    required this.iso2s,
    required this.visitedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
  });

  @override
  Widget build(BuildContext context) {
    final visitedCountries = iso2s.where(visitedCountryIds.contains).length;

    // Cities totals for this continent
    final totalCities = iso2s.fold<int>(0, (a, iso) => a + (iso2ToCities[iso]?.length ?? 0));
    final visitedCities = iso2s.fold<int>(0, (a, iso) => a + (citiesByCountry[iso]?.length ?? 0));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        actions: const [],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Header gauge (continent)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GradientGauge(visited: visitedCountries, total: iso2s.length, size: 92),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          continent,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('${S.t(context, 'tab_countries')} $visitedCountries/${iso2s.length}'),
                        Text('${S.t(context, 'cities')} $visitedCities/$totalCities'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Countries
          for (final iso in iso2s)
            _CountryRow(
              iso2: iso,
              name: countryNameById[iso] ?? iso,
              isVisited: visitedCountryIds.contains(iso),
              visitedCities: citiesByCountry[iso]?.length ?? 0,
              totalCities: iso2ToCities[iso]?.length ?? 0,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CountryCitiesPage(
                      iso2: iso,
                      countryName: countryNameById[iso] ?? iso,
                      visitedCountryIds: visitedCountryIds,
                      visitedCities: citiesByCountry[iso] ?? const <String>[],
                      allCities: iso2ToCities[iso] ?? const <String>[],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  final String iso2;
  final String name;
  final bool isVisited;
  final int visitedCities;
  final int totalCities;
  final VoidCallback onTap;

  const _CountryRow({
    required this.iso2,
    required this.name,
    required this.isVisited,
    required this.visitedCities,
    required this.totalCities,
    required this.onTap,
  });

  String _flagEmojiFromIso2(String iso2) {
    final s = iso2.toUpperCase();
    if (s.length != 2) return '🏳️';
    final a = s.codeUnitAt(0);
    final b = s.codeUnitAt(1);
    if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
    return String.fromCharCode(0x1F1E6 + (a - 65)) +
        String.fromCharCode(0x1F1E6 + (b - 65));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              GradientGauge(visited: visitedCities, total: totalCities, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_flagEmojiFromIso2(iso2), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              name,
                              maxLines: 1,
                              softWrap: false,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${S.t(context, 'cities')} $visitedCities/$totalCities', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isVisited ? Theme.of(context).colorScheme.primary : null,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
