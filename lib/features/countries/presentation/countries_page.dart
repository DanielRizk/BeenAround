import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../map/presentation/widgets/city_picker_sheet.dart';

class CountriesPage extends StatefulWidget {
  final ValueNotifier<Set<String>> selectedIds;
  final ValueNotifier<Map<String, List<String>>> citiesByCountry;

  /// ISO2 -> Country name
  final Map<String, String> countryNameById;

  /// ISO2 -> all available cities for that country
  final Map<String, List<String>> iso2ToCities;

  /// When true, renders without Scaffold/AppBar so it can be shown inside a bottom sheet.
  final bool asSheet;

  /// When true, the page is used as "Manage cities" sheet (editable UI).
  /// When false, it's the Countries tab (metadata editor).
  final bool editable;

  /// Metadata (shown/edited ONLY when editable == false)
  final ValueNotifier<Map<String, String>>? countryVisitedOn; // iso2 -> ISO date
  final ValueNotifier<Map<String, Map<String, String>>>? cityVisitedOn; // iso2 -> city -> ISO date
  final ValueNotifier<Map<String, Map<String, String>>>? cityNotes; // iso2 -> city -> note

  const CountriesPage({
    super.key,
    required this.selectedIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
    this.asSheet = false,
    this.editable = false,
    this.countryVisitedOn,
    this.cityVisitedOn,
    this.cityNotes,
  });

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  final Set<String> _expandedCountries = <String>{};

  // controllers for notes (so typing feels stable)
  final Map<String, TextEditingController> _noteCtrls = {};

  @override
  void dispose() {
    for (final c in _noteCtrls.values) {
      c.dispose();
    }
    _noteCtrls.clear();
    super.dispose();
  }

  TextEditingController _noteController(String iso2, String city, String initial) {
    final key = '$iso2::$city';
    return _noteCtrls.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (widget.asSheet) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    S.t(context, 'manage_cities'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: S.t(context, 'close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.selectedIds,
      builder: (context, ids, _) {
        if (ids.isEmpty) {
          return Center(child: Text(S.t(context, 'no_countries_selected')));
        }

        final sorted = ids.toList()
          ..sort((a, b) {
            final an = widget.countryNameById[a] ?? a;
            final bn = widget.countryNameById[b] ?? b;
            return an.compareTo(bn);
          });

        return ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: widget.citiesByCountry,
          builder: (context, citiesByCountry, __) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final iso2 = sorted[i];
                final name = widget.countryNameById[iso2] ?? iso2;
                final isExpanded = _expandedCountries.contains(iso2);

                final selectedCities =
                (citiesByCountry[iso2] ?? const <String>[]).toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                return _CountrySection(
                  iso2: iso2,
                  countryName: name,
                  selectedCities: selectedCities,
                  isExpanded: isExpanded,
                  editable: widget.editable,
                  countryVisitedOn: widget.countryVisitedOn,
                  cityVisitedOn: widget.cityVisitedOn,
                  cityNotes: widget.cityNotes,
                  noteControllerFactory: _noteController,
                  onToggleExpanded: (v) {
                    setState(() {
                      if (v) {
                        _expandedCountries.add(iso2);
                      } else {
                        _expandedCountries.remove(iso2);
                      }
                    });
                  },
                  onEditCities:
                  widget.editable ? () => _editCities(context, iso2, name) : null,
                  onRemoveCountry: widget.editable
                      ? () => _removeCountryWithConfirm(context, iso2)
                      : null,
                  onRemoveCity: (city) => _toggleCityOff(context, iso2, city, selectedCities),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _editCities(BuildContext context, String iso2, String countryName) async {
    final allCities = widget.iso2ToCities[iso2] ?? const <String>[];
    if (allCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'no_available_cities'))),
      );
      return;
    }

    final current = widget.citiesByCountry.value[iso2] ?? const <String>[];

    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CityPickerSheet(
        iso2: iso2,
        countryName: countryName,
        flag: _flagEmojiFromIso2(iso2),
        allCities: allCities,
        initiallySelected: current,
      ),
    );

    if (!mounted || picked == null) return;

    if (picked.isEmpty) {
      final ok = await _confirmRemoveLastCity(context);
      if (!mounted) return;
      if (ok == true) _removeCountry(iso2);
      return;
    }

    final next = Map<String, List<String>>.from(widget.citiesByCountry.value);
    next[iso2] = picked;
    widget.citiesByCountry.value = next;
  }

  Future<void> _toggleCityOff(
      BuildContext context,
      String iso2,
      String city,
      List<String> selectedCitiesSorted,
      ) async {
    if (selectedCitiesSorted.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'country_needs_at_least_one_city'))),
      );

      final ok = await _confirmRemoveLastCity(context);
      if (!mounted) return;
      if (ok == true) _removeCountry(iso2);
      return;
    }

    final current = widget.citiesByCountry.value[iso2] ?? const <String>[];
    final nextCities = current.where((c) => c != city).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final next = Map<String, List<String>>.from(widget.citiesByCountry.value);
    next[iso2] = nextCities;
    widget.citiesByCountry.value = next;
  }

  Future<void> _removeCountryWithConfirm(BuildContext context, String iso2) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t(context, 'remove_country')),
        content: Text(S.t(context, 'cities_will_be_lost_remove_country_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t(context, 'remove')),
          ),
        ],
      ),
    );

    if (ok == true) _removeCountry(iso2);
  }

  Future<bool?> _confirmRemoveLastCity(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t(context, 'remove_country')),
        content: Text(S.t(context, 'country_needs_at_least_one_city')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t(context, 'keep')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t(context, 'remove')),
          ),
        ],
      ),
    );
  }

  void _removeCountry(String iso2) {
    final nextSel = Set<String>.from(widget.selectedIds.value)..remove(iso2);
    widget.selectedIds.value = nextSel;

    final nextCities = Map<String, List<String>>.from(widget.citiesByCountry.value);
    nextCities.remove(iso2);
    widget.citiesByCountry.value = nextCities;

    setState(() => _expandedCountries.remove(iso2));
  }
}

class _CountrySection extends StatelessWidget {
  final String iso2;
  final String countryName;
  final List<String> selectedCities;

  final bool isExpanded;
  final bool editable;

  final ValueNotifier<Map<String, String>>? countryVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>>? cityVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>>? cityNotes;

  final ValueChanged<bool> onToggleExpanded;

  final VoidCallback? onEditCities;
  final VoidCallback? onRemoveCountry;

  final ValueChanged<String> onRemoveCity;

  final TextEditingController Function(String iso2, String city, String initial)
  noteControllerFactory;

  const _CountrySection({
    required this.iso2,
    required this.countryName,
    required this.selectedCities,
    required this.isExpanded,
    required this.editable,
    required this.countryVisitedOn,
    required this.cityVisitedOn,
    required this.cityNotes,
    required this.onToggleExpanded,
    required this.onEditCities,
    required this.onRemoveCountry,
    required this.onRemoveCity,
    required this.noteControllerFactory,
  });

  @override
  Widget build(BuildContext context) {
    final headerBg = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('country-$iso2'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onToggleExpanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
          collapsedShape:
          const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
          title: Row(
            children: [
              Text(_flagEmojiFromIso2(iso2), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(countryName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),

                    // Country visited date editable ONLY on Countries tab (editable == false)
                    if (!editable && countryVisitedOn != null)
                      ValueListenableBuilder<Map<String, String>>(
                        valueListenable: countryVisitedOn!,
                        builder: (context, map, _) {
                          final visitedIso = map[iso2];
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${S.t(context, "visited_on")}: ${_fmtDate(visitedIso)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: S.t(context, 'edit_date'),
                                icon: const Icon(Icons.edit_calendar, size: 18),
                                onPressed: () async {
                                  final picked = await _pickDate(context, visitedIso);
                                  if (picked == null) return;

                                  final next = Map<String, String>.from(countryVisitedOn!.value);
                                  next[iso2] = picked.toIso8601String();
                                  countryVisitedOn!.value = next;
                                },
                              ),
                            ],
                          );
                        },
                      ),

                    Text(
                      selectedCities.length == 1
                          ? '${selectedCities.length} ${S.t(context, "city")} ${S.t(context, "visited")}'
                          : '${selectedCities.length} ${S.t(context, "cities")} ${S.t(context, "visited")}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: editable
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: S.t(context, 'edit_cities'),
                icon: const Icon(Icons.add),
                onPressed: onEditCities,
              ),
              IconButton(
                tooltip: S.t(context, 'remove_country'),
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemoveCountry,
              ),
              Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ],
          )
              : Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          children: [
            if (selectedCities.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(S.t(context, 'no_cities_selected')),
                ),
              )
            else
              _CityGroup(
                editable: editable,
                iso2: iso2,
                cities: selectedCities,
                cityVisitedOn: cityVisitedOn,
                cityNotes: cityNotes,
                onRemoveCity: onRemoveCity,
                noteControllerFactory: noteControllerFactory,
              ),
          ],
        ),
      ),
    );
  }
}

class _CityGroup extends StatelessWidget {
  final bool editable;
  final String iso2;
  final List<String> cities;

  final ValueNotifier<Map<String, Map<String, String>>>? cityVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>>? cityNotes;

  final ValueChanged<String> onRemoveCity;

  final TextEditingController Function(String iso2, String city, String initial)
  noteControllerFactory;

  const _CityGroup({
    required this.editable,
    required this.iso2,
    required this.cities,
    required this.cityVisitedOn,
    required this.cityNotes,
    required this.onRemoveCity,
    required this.noteControllerFactory,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < cities.length; i++) ...[
            _CityRowModern(
              editable: editable,
              iso2: iso2,
              city: cities[i],
              cityVisitedOn: cityVisitedOn,
              cityNotes: cityNotes,
              onRemove: () => onRemoveCity(cities[i]),
              noteControllerFactory: noteControllerFactory,
            ),
            if (i != cities.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _CityRowModern extends StatefulWidget {
  final bool editable;
  final String iso2;
  final String city;

  final ValueNotifier<Map<String, Map<String, String>>>? cityVisitedOn;
  final ValueNotifier<Map<String, Map<String, String>>>? cityNotes;

  final TextEditingController Function(String iso2, String city, String initial)
  noteControllerFactory;

  final VoidCallback onRemove;

  const _CityRowModern({
    required this.editable,
    required this.iso2,
    required this.city,
    required this.cityVisitedOn,
    required this.cityNotes,
    required this.onRemove,
    required this.noteControllerFactory,
  });

  @override
  State<_CityRowModern> createState() => _CityRowModernState();
}

class _CityRowModernState extends State<_CityRowModern> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.editable) {
      // Manage cities: icon-only removal
      return ListTile(
        dense: true,
        title: Text(widget.city),
        trailing: IconButton(
          tooltip: S.t(context, 'remove'),
          icon: const Icon(Icons.delete_outline),
          onPressed: widget.onRemove,
        ),
        onTap: null,
      );
    }

    // Countries tab: edit date + note
    return ValueListenableBuilder<Map<String, Map<String, String>>>(
      valueListenable: widget.cityVisitedOn ?? ValueNotifier(const {}),
      builder: (context, visits, _) {
        final isoDate = visits[widget.iso2]?[widget.city];

        return ValueListenableBuilder<Map<String, Map<String, String>>>(
          valueListenable: widget.cityNotes ?? ValueNotifier(const {}),
          builder: (context, notes, __) {
            final storedNote = notes[widget.iso2]?[widget.city] ?? '';
            final noteTrimmed = storedNote.trim();

            final controller =
            widget.noteControllerFactory(widget.iso2, widget.city, storedNote);

            // keep controller synced if store changes elsewhere
            if (controller.text != storedNote && controller.value.composing.isCollapsed) {
              controller.text = storedNote;
            }

            final hasNote = noteTrimmed.isNotEmpty;
            final subtitle = '${S.t(context, "visited_on")}: ${_fmtDate(isoDate)}';

            return InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(widget.city),
                      subtitle: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: S.t(context, 'edit_date'),
                            icon: const Icon(Icons.calendar_month, size: 18),
                            onPressed: () async {
                              final vn = widget.cityVisitedOn;
                              if (vn == null) return;

                              final picked = await _pickDate(context, isoDate);
                              if (picked == null) return;

                              final nextAll = Map<String, Map<String, String>>.from(vn.value);
                              final nextForCountry =
                              Map<String, String>.from(nextAll[widget.iso2] ?? const {});
                              nextForCountry[widget.city] = picked.toIso8601String();
                              nextAll[widget.iso2] = nextForCountry;
                              vn.value = nextAll;
                            },
                          ),
                          if (hasNote) const Icon(Icons.note_alt_outlined, size: 18),
                          const SizedBox(width: 6),
                          Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
                        ],
                      ),
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: !_expanded
                          ? const SizedBox.shrink()
                          : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (txt) {
                                  final vn = widget.cityNotes;
                                  if (vn == null) return;

                                  final nextAll =
                                  Map<String, Map<String, String>>.from(vn.value);
                                  final nextForCountry = Map<String, String>.from(
                                      nextAll[widget.iso2] ?? const {});
                                  final trimmed = txt.trim();

                                  if (trimmed.isEmpty) {
                                    nextForCountry.remove(widget.city);
                                  } else {
                                    nextForCountry[widget.city] = txt;
                                  }

                                  if (nextForCountry.isEmpty) {
                                    nextAll.remove(widget.iso2);
                                  } else {
                                    nextAll[widget.iso2] = nextForCountry;
                                  }

                                  vn.value = nextAll;
                                  setState(() {}); // refresh note icon instantly
                                },
                              ),
                            ],
                          ),
                        ),
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

String _flagEmojiFromIso2(String iso2) {
  final s = iso2.toUpperCase();
  if (s.length != 2) return '🏳️';
  final a = s.codeUnitAt(0);
  final b = s.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
  return String.fromCharCode(0x1F1E6 + (a - 65)) +
      String.fromCharCode(0x1F1E6 + (b - 65));
}

Future<DateTime?> _pickDate(BuildContext context, String? currentIso) async {
  DateTime initial = DateTime.now();
  if (currentIso != null && currentIso.isNotEmpty) {
    final parsed = DateTime.tryParse(currentIso);
    if (parsed != null) initial = parsed;
  }

  return showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: DateTime(1900),
    lastDate: DateTime(2100),
  );
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
