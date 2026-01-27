import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/i18n/app_strings.dart';
import 'continent_countries_page.dart';
import 'widgets/gradient_gauge.dart';

class StatsPage extends StatelessWidget {
  final ValueListenable<Set<String>> selectedCountryIds;
  final ValueListenable<Map<String, List<String>>> citiesByCountry;

  final Map<String, String> countryNameById; // iso2 -> name (if available)
  final Map<String, List<String>> iso2ToCities; // iso2 -> all cities
  final Map<String, String> iso2ToContinent; // iso2 -> continent

  const StatsPage({
    super.key,
    required this.selectedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
    required this.iso2ToContinent,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedCountryIds,
      builder: (context, visitedCountriesSet, _) {
        return ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: citiesByCountry,
          builder: (context, visitedCitiesMap, __) {
            final totalCountries = iso2ToCities.keys.length; // ISO2 universe
            final visitedCountries = visitedCountriesSet.length;

            final totalCities = iso2ToCities.values.fold<int>(0, (a, b) => a + b.length);
            final visitedCities = visitedCitiesMap.values.fold<int>(0, (a, b) => a + b.length);

            final continents = _buildContinentsIndex();

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
                  _SectionHeader(title: S.t(context, 'worldwide')),
                  const SizedBox(height: 10),

                  // Worldwide cards (Countries / Cities)
                  Row(
                    children: [
                      Expanded(
                        child: _GaugeCard(
                          title: S.t(context, 'tab_countries'),
                          visited: visitedCountries,
                          total: totalCountries,
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GaugeCard(
                          title: S.t(context, 'cities'),
                          visited: visitedCities,
                          total: totalCities,
                          onTap: null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  _SectionHeader(title: S.t(context, 'continents')),
                  const SizedBox(height: 10),

                  // Continents list (cards with gauge)
                  for (final entry in continents)
                    _ContinentRowCard(
                      continent: entry.continent,
                      iso2s: entry.iso2s,
                      visitedCountryIds: visitedCountriesSet,
                      citiesByCountry: visitedCitiesMap,
                      countryNameById: countryNameById,
                      iso2ToCities: iso2ToCities,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ContinentCountriesPage(
                              continent: entry.continent,
                              iso2s: entry.iso2s,
                              visitedCountryIds: visitedCountriesSet,
                              citiesByCountry: visitedCitiesMap,
                              countryNameById: countryNameById,
                              iso2ToCities: iso2ToCities,
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 8),

                  // Optional: quick access to a country if you want later
                  // (skip for now)
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_ContinentBucket> _buildContinentsIndex() {
    // Build from ISO2 universe (cities dataset keys)
    final buckets = <String, List<String>>{};

    for (final rawIso2 in iso2ToCities.keys) {
      final iso2 = rawIso2.trim().toUpperCase();
      final continent = iso2ToContinent[iso2] ?? 'Other';
      buckets.putIfAbsent(continent, () => <String>[]).add(iso2);
    }

    final out = buckets.entries
        .map((e) => _ContinentBucket(e.key, (e.value..sort())))
        .toList();

    // Put "Other" at the end
    out.sort((a, b) {
      if (a.continent == 'Other') return 1;
      if (b.continent == 'Other') return -1;
      return a.continent.compareTo(b.continent);
    });

    return out;
  }
}

class _ContinentBucket {
  final String continent;
  final List<String> iso2s;
  _ContinentBucket(this.continent, this.iso2s);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final String title;
  final int visited;
  final int total;
  final VoidCallback? onTap; // ✅ nullable

  const _GaugeCard({
    required this.title,
    required this.visited,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          GradientGauge(visited: visited, total: total, size: 96),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return Card(
      child: onTap == null
          ? content // ✅ no InkWell, no tap effect
          : InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      ),
    );
  }
}


class _ContinentRowCard extends StatelessWidget {
  final String continent;
  final List<String> iso2s;
  final Set<String> visitedCountryIds;
  final Map<String, List<String>> citiesByCountry;
  final Map<String, String> countryNameById;
  final Map<String, List<String>> iso2ToCities;
  final VoidCallback onTap;

  const _ContinentRowCard({
    required this.continent,
    required this.iso2s,
    required this.visitedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visitedCountries = iso2s.where(visitedCountryIds.contains).length;
    final totalCountries = iso2s.length;

    // You can also show cities coverage; but per your spec, gauge for “countries/cities visited”
    // We'll use countries gauge here, and show a small cities line in subtitle.
    final totalCities = iso2s.fold<int>(0, (a, iso) => a + (iso2ToCities[iso]?.length ?? 0));
    final visitedCities = iso2s.fold<int>(0, (a, iso) => a + (citiesByCountry[iso]?.length ?? 0));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GradientGauge(visited: visitedCountries, total: totalCountries, size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      continent,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${S.t(context, 'tab_countries')} $visitedCountries/$totalCountries',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${S.t(context, 'cities')} $visitedCities/$totalCities',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
