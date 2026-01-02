import 'package:flutter/material.dart';

import '../features/countries/presentation/countries_page.dart';
import '../features/friends/presentation/friends_page.dart';
import '../features/map/presentation/map_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/stats/presentation/stats_page.dart';
import '../shared/cities/cities_repository.dart';
import '../shared/map/world_map_loader.dart';
import '../shared/map/world_map_models.dart';

class BeenAroundApp extends StatelessWidget {
  const BeenAroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Been Around',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final ValueNotifier<Set<String>> selectedCountryIds =
  ValueNotifier<Set<String>>(<String>{});

  final ValueNotifier<Map<String, List<String>>> citiesByCountry =
  ValueNotifier<Map<String, List<String>>>({});

  late final Future<(WorldMapData, Map<String, List<String>>)> _bootstrapFuture;
  Map<String, List<String>> _iso2ToCities = const {};


  @override
  void initState() {
    super.initState();

    // ✅ Important: compute anchors BEFORE showing pages.
    _bootstrapFuture = Future.wait([
      WorldMapLoader.loadFromAssetWithAnchors('assets/maps/world.svg'),
      CitiesRepository.loadIso2ToCities('assets/cities/cities.csv'),
    ]).then((list) {
      final mapData = list[0] as WorldMapData;
      final cities = list[1] as Map<String, List<String>>;
      _iso2ToCities = cities;
      return (mapData, cities);
    });
  }

  @override
  void dispose() {
    selectedCountryIds.dispose();
    citiesByCountry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(WorldMapData, Map<String, List<String>>)>(
      future: _bootstrapFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load assets:\n\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final (mapData, iso2ToCities) = snap.data!; // ✅ unpack tuple

        if (mapData.labelAnchorById.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Map loaded, but anchors are empty.\n'
                    'Make sure WorldMapLoader.loadFromAssetWithAnchors() returns labelAnchorById.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final pages = <Widget>[
          MapPage(
            worldMap: mapData,
            selectedIds: selectedCountryIds,
            citiesByCountry: citiesByCountry,
            iso2ToCities: iso2ToCities, // ✅ now defined
          ),
          CountriesPage(
            editable: false,
            selectedIds: selectedCountryIds,
            citiesByCountry: citiesByCountry,
            countryNameById: mapData.nameById,
            iso2ToCities: iso2ToCities,
          ),
          const StatsPage(),
          const FriendsPage(),
          const SettingsPage(),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.public), label: 'Map'),
              NavigationDestination(icon: Icon(Icons.flag), label: 'Countries'),
              NavigationDestination(icon: Icon(Icons.insights), label: 'Stats'),
              NavigationDestination(icon: Icon(Icons.group), label: 'Friends'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }
}
