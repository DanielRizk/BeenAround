// import 'package:flutter/material.dart';
// import 'country_stats_page.dart';
//
// class ContinentStatsPage extends StatelessWidget {
//   final Set<String> visitedCountryIds;
//   final Map<String, List<String>> citiesByCountry;
//   final Map<String, String> countryNameById;
//
//   /// All cities in the world dataset by ISO2 (comes from CSV)
//   final Map<String, List<String>> iso2ToCities;
//
//   /// ISO2 -> Continent (loaded from your continent CSV)
//   final Map<String, String> iso2ToContinent;
//
//   const ContinentStatsPage({
//     super.key,
//     required this.visitedCountryIds,
//     required this.citiesByCountry,
//     required this.countryNameById,
//     required this.iso2ToCities,
//     required this.iso2ToContinent,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // ✅ IMPORTANT: group using ISO2 universe from cities dataset (guaranteed ISO2)
//     final byContinent = _groupIso2ByContinent(iso2ToCities.keys, iso2ToContinent);
//
//     // Sort continents by visited count desc (then name) for nicer UX
//     final continents = byContinent.keys.toList()
//       ..sort((a, b) {
//         final av = byContinent[a]!.where(visitedCountryIds.contains).length;
//         final bv = byContinent[b]!.where(visitedCountryIds.contains).length;
//         final cmp = bv.compareTo(av);
//         return cmp != 0 ? cmp : a.compareTo(b);
//       });
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('By Continent')),
//       body: ListView(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         children: [
//           for (final continent in continents)
//             _ContinentCard(
//               continent: continent,
//               countries: byContinent[continent]!,
//               visitedCountryIds: visitedCountryIds,
//               citiesByCountry: citiesByCountry,
//               countryNameById: countryNameById,
//               iso2ToCities: iso2ToCities,
//               onOpen: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => CountryStatsPage(
//                       continent: continent,
//                       countries: byContinent[continent]!,
//                       visitedCountryIds: visitedCountryIds,
//                       citiesByCountry: citiesByCountry,
//                       countryNameById: countryNameById,
//                       iso2ToCities: iso2ToCities,
//                     ),
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }
//
//   Map<String, List<String>> _groupIso2ByContinent(
//       Iterable<String> iso2s,
//       Map<String, String> iso2ToContinent,
//       ) {
//     final out = <String, List<String>>{};
//
//     for (final raw in iso2s) {
//       final iso = raw.trim().toUpperCase();
//       if (iso.isEmpty) continue;
//       final continent = iso2ToContinent[iso] ?? 'Other';
//       out.putIfAbsent(continent, () => <String>[]).add(iso);
//     }
//
//     // stable ordering inside each continent
//     for (final v in out.values) {
//       v.sort();
//     }
//
//     return out;
//   }
// }
//
// class _ContinentCard extends StatelessWidget {
//   final String continent;
//   final List<String> countries;
//   final Set<String> visitedCountryIds;
//   final Map<String, List<String>> citiesByCountry;
//   final Map<String, String> countryNameById;
//   final Map<String, List<String>> iso2ToCities;
//   final VoidCallback onOpen;
//
//   const _ContinentCard({
//     required this.continent,
//     required this.countries,
//     required this.visitedCountryIds,
//     required this.citiesByCountry,
//     required this.countryNameById,
//     required this.iso2ToCities,
//     required this.onOpen,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final visited = countries.where(visitedCountryIds.contains).length;
//     final total = countries.length;
//     final ratio = total == 0 ? 0.0 : visited / total;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onOpen,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       continent,
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                   ),
//                   const Icon(Icons.chevron_right),
//                 ],
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 '$visited / $total countries visited',
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 10),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(999),
//                 child: LinearProgressIndicator(value: ratio),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
