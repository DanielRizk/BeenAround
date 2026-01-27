import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/i18n/app_strings.dart';
import 'widgets/gradient_gauge.dart';

class CountryCitiesPage extends StatelessWidget {
  final String iso2;
  final String countryName;

  final Set<String> visitedCountryIds;
  final List<String> visitedCities;
  final List<String> allCities;

  const CountryCitiesPage({
    super.key,
    required this.iso2,
    required this.countryName,
    required this.visitedCountryIds,
    required this.visitedCities,
    required this.allCities,
  });

  @override
  Widget build(BuildContext context) {
    final visitedSet = visitedCities.map((e) => e.trim()).toSet();
    final allSorted = [...allCities]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final visitedCount = visitedSet.length;
    final totalCount = allCities.length;

    final isVisitedCountry = visitedCountryIds.contains(iso2);

    String _flagEmojiFromIso2(String iso2) {
      final s = iso2.toUpperCase();
      if (s.length != 2) return '🏳️';
      final a = s.codeUnitAt(0);
      final b = s.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCode(0x1F1E6 + (a - 65)) +
          String.fromCharCode(0x1F1E6 + (b - 65));
    }

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
          // Country header gauge
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GradientGauge(visited: visitedCount, total: totalCount, size: 92),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_flagEmojiFromIso2(iso2), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  countryName,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${S.t(context, "cities")} $visitedCount/$totalCount'),
                        Text(
                          isVisitedCountry ? S.t(context, "country_visited") : S.t(context, "country_not_visited"),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          Text(S.t(context, "cities"), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // Cities list: visited normal, unvisited greyed
          for (final city in allSorted)
            _CityRow(
              city: city,
              visited: visitedSet.contains(city.trim()),
            ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  final String city;
  final bool visited;

  const _CityRow({
    required this.city,
    required this.visited,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Opacity(
      opacity: visited ? 1.0 : 0.45,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Icon(visited ? Icons.check_circle : Icons.circle_outlined),
          title: Text(city, style: textStyle),
        ),
      ),
    );
  }
}
