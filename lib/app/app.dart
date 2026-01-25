import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/countries/presentation/countries_page.dart';
import '../features/friends/presentation/friends_page.dart';
import '../features/map/presentation/map_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/stats/presentation/stats_page.dart';
import '../shared/cities/cities_repository.dart';
import '../shared/geo/continent_repository.dart';
import '../shared/i18n/app_strings.dart';
import '../shared/map/world_map_loader.dart';
import '../shared/map/world_map_models.dart';
import '../shared/settings/app_settings.dart';
import '../shared/storage/local_store.dart';

// TODO: Fix the cities data
// TODO(DONE): Click on selected country, opens a menu to show information and metadata and for the cities as well, allow edit mode.
// TODO: Implement statistics page, show overview countries percentage and cities percentage with nice graphs, click on countries and select each country to see statistics.
// TODO: Implement Login page and tutorial, allow manual login or by google Auth0.
// TODO: Implement backup server and store user data countries, cities and friends.
// TODO: Implement Friends page, add friends, click on a friend to see his map countries cities and statistics.
// TODO: Design a Logo, Icon, Animated Icon for loading.
// TODO: Implement Feed in friends page to see latest updates from friends (allow in setting the activity to show on feed per user).
// TODO: Add GPS tracking for users (Allowed in settings) to automatically detect countries and cities (if not added before), and send notification to instant add them.
// =============================================================================
// TODO: Explore the option of adding cities markers on countries.
// TODO: Explore adding a notification center (to receive likes on activites, friend request and so on.)
// TODO: Explore adding "Planner Page" to set plans and goals.

class BeenAroundApp extends StatelessWidget {
  const BeenAroundApp({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: settings,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'Been Around',
            debugShowCheckedModeBanner: false,

            // ✅ required for Localizations.localeOf(context) to work + update
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('de'),
            ],

            // ✅ your controller-driven locale
            locale: settings.locale,

            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: settings.colorSchemeSeed,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: settings.colorSchemeSeed,
              brightness: Brightness.dark,
            ),

            home: const HomeShell(),
          );

        },
      ),
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

  // ✅ New: visit metadata (persisted)
  final ValueNotifier<Map<String, String>> countryVisitedOn =
      ValueNotifier<Map<String, String>>({}); // iso2 -> ISO date
  final ValueNotifier<Map<String, Map<String, String>>> cityVisitedOn =
      ValueNotifier<Map<String, Map<String, String>>>({}); // iso2 -> city -> ISO date
  final ValueNotifier<Map<String, Map<String, String>>> cityNotes =
      ValueNotifier<Map<String, Map<String, String>>>({}); // iso2 -> city -> note

  late final Future<(WorldMapData, Map<String, List<String>>)> _bootstrapFuture;
  Map<String, String> _iso2ToContinent = const {};
  Map<String, List<String>> _iso2ToCities = const {};

  bool _reconciling = false;

  @override
  void initState() {
    super.initState();

    _bootstrapFuture = Future.wait([
      WorldMapLoader.loadFromAssetWithAnchors('assets/maps/world.svg'),
      CitiesRepository.loadIso2ToCities('assets/cities/cities.csv'),
      ContinentRepository.loadIso2ToContinent('assets/geo/country_continents.csv'),
      // load saved user selections
      LocalStore.loadSelectedCountries(),
      LocalStore.loadCitiesByCountry(),

      // ✅ load saved metadata
      LocalStore.loadCountryVisitedOn(),
      LocalStore.loadCityVisitedOn(),
      LocalStore.loadCityNotes(),
    ]).then((list) {
      final mapData = list[0] as WorldMapData;
      final cities = list[1] as Map<String, List<String>>;
      final continentMap = list[2] as Map<String, String>;

      final savedSelected = list[3] as Set<String>;
      final savedCitiesByCountry = list[4] as Map<String, List<String>>;

      final savedCountryVisitedOn = list[5] as Map<String, String>;
      final savedCityVisitedOn = list[6] as Map<String, Map<String, String>>;
      final savedCityNotes = list[7] as Map<String, Map<String, String>>;

      debugPrint('continentMap length = ${continentMap.length}');
      debugPrint('continentMap sample = ${continentMap.entries.take(10).toList()}');
      debugPrint('iso2ToCities keys sample = ${cities.keys.take(10).toList()}');

      _iso2ToCities = cities;
      _iso2ToContinent = continentMap;

      // ✅ hydrate notifiers
      selectedCountryIds.value = savedSelected;
      citiesByCountry.value = savedCitiesByCountry;

      countryVisitedOn.value = savedCountryVisitedOn;
      cityVisitedOn.value = savedCityVisitedOn;
      cityNotes.value = savedCityNotes;

      _reconcileMetadata();

      // ✅ start auto-saving on changes
      selectedCountryIds.addListener(() {
        LocalStore.saveSelectedCountries(selectedCountryIds.value);
        _reconcileMetadata();
      });
      citiesByCountry.addListener(() {
        LocalStore.saveCitiesByCountry(citiesByCountry.value);
        _reconcileMetadata();
      });

      countryVisitedOn.addListener(() {
        LocalStore.saveCountryVisitedOn(countryVisitedOn.value);
      });
      cityVisitedOn.addListener(() {
        LocalStore.saveCityVisitedOn(cityVisitedOn.value);
      });
      cityNotes.addListener(() {
        LocalStore.saveCityNotes(cityNotes.value);
      });

      return (mapData, cities);
    });
  }

  void _reconcileMetadata() {
    if (_reconciling) return;
    _reconciling = true;
    try {
      final visited = selectedCountryIds.value;
      final citiesMap = citiesByCountry.value;

      final today = DateTime.now();
      final todayIso = DateTime(today.year, today.month, today.day).toIso8601String();

      // Country dates
      final nextCountry = Map<String, String>.from(countryVisitedOn.value);
      // remove unvisited
      nextCountry.removeWhere((k, _) => !visited.contains(k));
      // add missing
      for (final iso2 in visited) {
        nextCountry.putIfAbsent(iso2, () => todayIso);
      }
      if (!_shallowMapEquals(countryVisitedOn.value, nextCountry)) {
        countryVisitedOn.value = nextCountry;
      }

      // City visited dates
      final nextCityVisited = _deepCopy(cityVisitedOn.value);
      nextCityVisited.removeWhere((k, _) => !visited.contains(k));
      for (final iso2 in visited) {
        final cities = (citiesMap[iso2] ?? const <String>[]);
        final m = Map<String, String>.from(nextCityVisited[iso2] ?? const {});
        // remove cities no longer selected
        m.removeWhere((city, _) => !cities.contains(city));
        // add missing cities
        for (final city in cities) {
          m.putIfAbsent(city, () => todayIso);
        }
        if (m.isEmpty) {
          nextCityVisited.remove(iso2);
        } else {
          nextCityVisited[iso2] = m;
        }
      }
      if (!_deepMapEquals(cityVisitedOn.value, nextCityVisited)) {
        cityVisitedOn.value = nextCityVisited;
      }

      // City notes (only cleanup; don't auto-create empty notes)
      final nextNotes = _deepCopy(cityNotes.value);
      nextNotes.removeWhere((k, _) => !visited.contains(k));
      for (final iso2 in visited) {
        final cities = (citiesMap[iso2] ?? const <String>[]);
        final m = Map<String, String>.from(nextNotes[iso2] ?? const {});
        m.removeWhere((city, _) => !cities.contains(city));
        if (m.isEmpty) {
          nextNotes.remove(iso2);
        } else {
          nextNotes[iso2] = m;
        }
      }
      if (!_deepMapEquals(cityNotes.value, nextNotes)) {
        cityNotes.value = nextNotes;
      }
    } finally {
      _reconciling = false;
    }
  }

  Map<String, Map<String, String>> _deepCopy(Map<String, Map<String, String>> src) {
    final out = <String, Map<String, String>>{};
    for (final e in src.entries) {
      out[e.key] = Map<String, String>.from(e.value);
    }
    return out;
  }

  bool _shallowMapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  bool _deepMapEquals(Map<String, Map<String, String>> a, Map<String, Map<String, String>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final bm = b[e.key];
      if (bm == null) return false;
      final am = e.value;
      if (am.length != bm.length) return false;
      for (final ce in am.entries) {
        if (bm[ce.key] != ce.value) return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    selectedCountryIds.dispose();
    citiesByCountry.dispose();
    countryVisitedOn.dispose();
    cityVisitedOn.dispose();
    cityNotes.dispose();
    super.dispose();
  }

  Future<void> _resetAllAppData() async {
    // 1) clear persisted
    await LocalStore.clearSelectionData();
    await AppSettingsScope.of(context).resetToDefaults();

    // 2) clear in-memory so UI updates immediately
    selectedCountryIds.value = <String>{};
    citiesByCountry.value = <String, List<String>>{};
    countryVisitedOn.value = <String, String>{};
    cityVisitedOn.value = <String, Map<String, String>>{};
    cityNotes.value = <String, Map<String, String>>{};
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
            iso2ToCities: iso2ToCities,
            countryVisitedOn: countryVisitedOn,
            cityVisitedOn: cityVisitedOn,
            cityNotes: cityNotes,
          ),
          CountriesPage(
            editable: false,
            selectedIds: selectedCountryIds,
            citiesByCountry: citiesByCountry,
            countryNameById: mapData.nameById,
            iso2ToCities: iso2ToCities,

            countryVisitedOn: countryVisitedOn,
            cityVisitedOn: cityVisitedOn,
            cityNotes: cityNotes,
          ),
          StatsPage(
            selectedCountryIds: selectedCountryIds,
            citiesByCountry: citiesByCountry,
            countryNameById: mapData.nameById,
            iso2ToCities: iso2ToCities,
            iso2ToContinent: _iso2ToContinent,
          ),

          const FriendsPage(),
          SettingsPage(onResetAll: _resetAllAppData),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            //labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.public),
                label: S.t(context, 'tab_map'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.flag),
                label: S.t(context, 'tab_countries'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights),
                label: S.t(context, 'tab_stats'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.group),
                label: S.t(context, 'tab_friends'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings),
                label: S.t(context, 'tab_settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}

