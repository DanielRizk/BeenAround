import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'widgets/donut_chart.dart';
import 'continent_stats_page.dart';

class StatsPage extends StatelessWidget {
  final ValueListenable<Set<String>> selectedCountryIds;
  final ValueListenable<Map<String, List<String>>> citiesByCountry;
  final Map<String, String> iso2ToContinent;

  final Map<String, String> countryNameById;
  final Map<String, List<String>> iso2ToCities;

  const StatsPage({
    super.key,
    required this.selectedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
    required this.iso2ToContinent
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedCountryIds,
      builder: (context, visitedSet, _) {
        return ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: citiesByCountry,
          builder: (context, citiesMap, __) {
            final totalCountries = countryNameById.length;
            final totalCities =
            iso2ToCities.values.fold<int>(0, (a, b) => a + b.length);

            final visitedCountries = visitedSet.length;
            final visitedCities =
            citiesMap.values.fold<int>(0, (a, b) => a + b.length);

            return Scaffold(
              appBar: AppBar(title: const Text('Statistics')),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsCard(
                    title: 'Visited Countries',
                    subtitle: '$visitedCountries / $totalCountries',
                    percent: totalCountries == 0
                        ? 0
                        : visitedCountries / totalCountries,
                    onTap: () => _openContinents(context, visitedSet, citiesMap),
                  ),
                  const SizedBox(height: 16),
                  _StatsCard(
                    title: 'Visited Cities',
                    subtitle: '$visitedCities / $totalCities',
                    percent:
                    totalCities == 0 ? 0 : visitedCities / totalCities,
                    onTap: () => _openContinents(context, visitedSet, citiesMap),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openContinents(
      BuildContext context,
      Set<String> visitedSet,
      Map<String, List<String>> citiesMap,
      ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContinentStatsPage(
          visitedCountryIds: visitedSet,
          citiesByCountry: citiesMap,
          countryNameById: countryNameById,
          iso2ToCities: iso2ToCities,
          iso2ToContinent: iso2ToContinent,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double percent;
  final VoidCallback onTap;

  const _StatsCard({
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DonutChart(percent: percent, size: 90),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
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
