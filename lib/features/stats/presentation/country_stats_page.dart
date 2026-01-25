import 'package:flutter/material.dart';
import 'widgets/donut_chart.dart';

class CountryStatsPage extends StatelessWidget {
  final String continent;
  final List<String> countries;
  final Set<String> visitedCountryIds;
  final Map<String, List<String>> citiesByCountry;
  final Map<String, String> countryNameById;
  final Map<String, List<String>> iso2ToCities;

  const CountryStatsPage({
    super.key,
    required this.continent,
    required this.countries,
    required this.visitedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(continent)),
      body: ListView(
        children: countries.map((iso) {
          final visitedCities = citiesByCountry[iso]?.length ?? 0;
          final totalCities = iso2ToCities[iso]?.length ?? 0;
          final percent =
          totalCities == 0 ? 0.0 : visitedCities / totalCities;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(countryNameById[iso] ?? iso),
              subtitle: Text('$visitedCities / $totalCities cities'),
              leading: DonutChart(percent: percent, size: 50),
              trailing: visitedCountryIds.contains(iso)
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.radio_button_unchecked),
            ),
          );
        }).toList(),
      ),
    );
  }
}
