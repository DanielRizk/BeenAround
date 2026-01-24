import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../countries/presentation/countries_page.dart';
import '../widgets/world_map_view.dart';
import 'widgets/country_picker_sheet.dart';

class MapPage extends StatefulWidget {
  final WorldMapData worldMap;
  final ValueNotifier<Set<String>> selectedIds;

  final ValueNotifier<Map<String, List<String>>> citiesByCountry;
  final Map<String, List<String>> iso2ToCities;

  // ✅ New: metadata
  final ValueNotifier<Map<String, String>> countryVisitedOn; // iso2 -> ISO date
  final ValueNotifier<Map<String, Map<String, String>>> cityVisitedOn; // iso2 -> city -> ISO date
  final ValueNotifier<Map<String, Map<String, String>>> cityNotes; // iso2 -> city -> note

  const MapPage({
    super.key,
    required this.worldMap,
    required this.selectedIds,
    required this.citiesByCountry,
    required this.iso2ToCities,
    required this.countryVisitedOn,
    required this.cityVisitedOn,
    required this.cityNotes,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<WorldMapViewState> _mapKey = GlobalKey<WorldMapViewState>();

  String? _focusedIso2;

  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    _noteControllers.clear();
    super.dispose();
  }

  void _openAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(S.t(context, 'add_country')),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCountryPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(S.t(context, 'add_city')),
                subtitle: Text(S.t(context, 'add_city_subtitle')),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCityManager(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCountryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return CountryPickerSheet(
          worldMap: widget.worldMap,
          selectedIds: widget.selectedIds,
          citiesByCountry: widget.citiesByCountry,
          iso2ToCities: widget.iso2ToCities,
        );
      },
    );
  }

  void _openCityManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return CountriesPage(
          asSheet: true,
          editable: true,
          selectedIds: widget.selectedIds,
          citiesByCountry: widget.citiesByCountry,
          countryNameById: widget.worldMap.nameById,
          iso2ToCities: widget.iso2ToCities,

          countryVisitedOn: widget.countryVisitedOn,
          cityVisitedOn: widget.cityVisitedOn,
          cityNotes: widget.cityNotes,
        );
      },
    );
  }

  void _onCountryTap(String iso2) {
    // ✅ Only react for visited countries
    final visited = widget.selectedIds.value.contains(iso2);
    if (!visited) return;

    setState(() => _focusedIso2 = iso2);
    // zoom
    _mapKey.currentState?.focusCountry(iso2);
  }

  void _closeDetails() {
    setState(() => _focusedIso2 = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WorldMapView(
            key: _mapKey,
            map: widget.worldMap,
            selectedIds: widget.selectedIds,
            onCountryTap: _onCountryTap,
          ),

          // Overlay details
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _focusedIso2 == null
                ? const SizedBox.shrink()
                : _CountryDetailsOverlay(
                    key: ValueKey(_focusedIso2),
                    iso2: _focusedIso2!,
                    worldMap: widget.worldMap,
                    citiesByCountry: widget.citiesByCountry,
                    countryVisitedOn: widget.countryVisitedOn,
                    cityVisitedOn: widget.cityVisitedOn,
                    cityNotes: widget.cityNotes,
                    noteControllers: _noteControllers,
                    onClose: _closeDetails,
                  ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _focusedIso2 == null
            ? FloatingActionButton(
          key: const ValueKey('fab_add'),
          onPressed: () => _openAddMenu(context),
          child: const Icon(Icons.add),
        )
            : const SizedBox.shrink(key: ValueKey('fab_hidden')),
      ),

    );
  }
}

class _CountryDetailsOverlay extends StatelessWidget {
  final String iso2;
  final WorldMapData worldMap;

  final ValueNotifier<Map<String, List<String>>> citiesByCountry;
  final ValueNotifier<Map<String, String>> countryVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>> cityVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>> cityNotes;

  final Map<String, TextEditingController> noteControllers;

  final VoidCallback onClose;

  const _CountryDetailsOverlay({
    super.key,
    required this.iso2,
    required this.worldMap,
    required this.citiesByCountry,
    required this.countryVisitedOn,
    required this.cityVisitedOn,
    required this.cityNotes,
    required this.noteControllers,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = worldMap.nameById[iso2] ?? iso2;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: ValueListenableBuilder<Map<String, List<String>>>(
                  valueListenable: citiesByCountry,
                  builder: (context, citiesMap, _) {
                    final cities = List<String>.from(citiesMap[iso2] ?? const <String>[])
                      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row
                        Row(
                          children: [
                            IconButton(
                              tooltip: S.t(context, 'back'),
                              onPressed: onClose,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _flagEmojiFromIso2(iso2),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Country visited date
                        ValueListenableBuilder<Map<String, String>>(
                          valueListenable: countryVisitedOn,
                          builder: (context, map, _) {
                            final iso = map[iso2];
                            return _DateRow(
                              label: S.t(context, 'visited_on'),
                              value: _fmtDate(iso),
                              onEdit: () async {
                                final picked = await _pickDate(context, iso);
                                if (picked == null) return;
                                final next = Map<String, String>.from(countryVisitedOn.value);
                                next[iso2] = picked.toIso8601String();
                                countryVisitedOn.value = next;
                              },
                            );
                          },
                        ),

                        const Divider(height: 18),

                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (final city in cities)
                                  _CityItem(
                                    iso2: iso2,
                                    city: city,
                                    cityVisitedOn: cityVisitedOn,
                                    cityNotes: cityNotes,
                                    noteControllers: noteControllers,
                                  ),
                                if (cities.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      S.t(context, 'no_cities_selected'),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CityItem extends StatelessWidget {
  final String iso2;
  final String city;

  final ValueNotifier<Map<String, Map<String, String>>> cityVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>> cityNotes;

  final Map<String, TextEditingController> noteControllers;

  const _CityItem({
    required this.iso2,
    required this.city,
    required this.cityVisitedOn,
    required this.cityNotes,
    required this.noteControllers,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, Map<String, String>>>(
      valueListenable: cityVisitedOn,
      builder: (context, visits, _) {
        final iso = visits[iso2]?[city];

        return ValueListenableBuilder<Map<String, Map<String, String>>>(
          valueListenable: cityNotes,
          builder: (context, notes, __) {
            final noteKey = '$iso2::$city';
            final existingNote = notes[iso2]?[city] ?? '';

            final controller = noteControllers.putIfAbsent(
              noteKey,
              () => TextEditingController(text: existingNote),
            );

            // keep controller in sync if data changes elsewhere
            if (controller.text != existingNote && controller.value.composing.isCollapsed) {
              controller.text = existingNote;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(city, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${S.t(context, 'visited_on')}: ${_fmtDate(iso)}'),
                  trailing: IconButton(
                    tooltip: S.t(context, 'edit_date'),
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final picked = await _pickDate(context, iso);
                      if (picked == null) return;

                      final nextAll = Map<String, Map<String, String>>.from(cityVisitedOn.value);
                      final nextForCountry = Map<String, String>.from(nextAll[iso2] ?? const {});
                      nextForCountry[city] = picked.toIso8601String();
                      nextAll[iso2] = nextForCountry;
                      cityVisitedOn.value = nextAll;
                    },
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.t(context, 'notes'),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: S.t(context, 'add_note'),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (txt) {
                              final nextAll = Map<String, Map<String, String>>.from(cityNotes.value);
                              final nextForCountry = Map<String, String>.from(nextAll[iso2] ?? const {});
                              if (txt.trim().isEmpty) {
                                nextForCountry.remove(city);
                              } else {
                                nextForCountry[city] = txt;
                              }
                              if (nextForCountry.isEmpty) {
                                nextAll.remove(iso2);
                              } else {
                                nextAll[iso2] = nextForCountry;
                              }
                              cityNotes.value = nextAll;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _DateRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          tooltip: S.t(context, 'edit_date'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_calendar),
        ),
      ],
    );
  }
}

Future<DateTime?> _pickDate(BuildContext context, String? currentIso) async {
  DateTime initial = DateTime.now();
  if (currentIso != null) {
    final parsed = DateTime.tryParse(currentIso);
    if (parsed != null) initial = parsed;
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: DateTime(1900),
    lastDate: DateTime(2100),
  );
  return picked;
}

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _flagEmojiFromIso2(String iso2) {
  final s = iso2.toUpperCase();
  if (s.length != 2) return '🏳️';
  final a = s.codeUnitAt(0);
  final b = s.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
  return String.fromCharCode(0x1F1E6 + (a - 65)) +
      String.fromCharCode(0x1F1E6 + (b - 65));
}
