import 'package:flutter/material.dart';

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
  final bool editable;

  const CountriesPage({
    super.key,
    required this.selectedIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
    this.asSheet = false,
    this.editable = true,
  });

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  final Set<String> _expanded = <String>{};

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
                    'Manage cities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
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
          return const Center(child: Text('No countries selected yet.'));
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
                final isExpanded = _expanded.contains(iso2);

                final selectedCities =
                (citiesByCountry[iso2] ?? const <String>[]).toList()..sort();

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent, // 🚫 kill ExpansionTile dividers
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey('country-$iso2'),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (v) {
                        setState(() {
                          if (v) {
                            _expanded.add(iso2);
                          } else {
                            _expanded.remove(iso2);
                          }
                        });
                      },

                      // 🚫 remove top & bottom border lines when expanded
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.transparent),
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.transparent),
                      ),

                      title: Row(
                        children: [
                          Text(
                            _flagEmojiFromIso2(iso2),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${selectedCities.length} cit${selectedCities.length == 1 ? 'y' : 'ies'} visited',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: isExpanded
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.editable) ...[
                            IconButton(
                              tooltip: 'Edit cities',
                              icon: const Icon(Icons.add),
                              onPressed: () => _editCities(context, iso2, name),
                            ),
                            IconButton(
                              tooltip: 'Remove country',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeCountryWithConfirm(context, iso2),
                            ),
                            const SizedBox(width: 4),
                          ],
                          const Icon(Icons.expand_less),
                        ],
                      )
                          : const Icon(Icons.expand_more),
                      children: [
                        if (selectedCities.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text('No cities selected.'),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Column(
                              children: [
                                for (final city in selectedCities)
                                  widget.editable
                                      ? CheckboxListTile(
                                    value: true,
                                    onChanged: (v) {
                                      if (v == false) {
                                        _toggleCityOff(
                                          context,
                                          iso2,
                                          city,
                                          selectedCities,
                                        );
                                      }
                                    },
                                    title: Text(city),
                                    controlAffinity:
                                    ListTileControlAffinity.trailing,
                                    dense: true,
                                  )
                                      : ListTile(
                                    title: Text(
                                      city,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    dense: true,
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
      },
    );
  }

  Future<void> _editCities(
      BuildContext context, String iso2, String countryName) async {
    final allCities = widget.iso2ToCities[iso2] ?? const <String>[];
    if (allCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cities available for this country.')),
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
        const SnackBar(
          content: Text(
            'A country needs at least one city. If you uncheck this city the country will be removed.',
          ),
        ),
      );

      final ok = await _confirmRemoveLastCity(context);
      if (!mounted) return;
      if (ok == true) _removeCountry(iso2);
      return;
    }

    final current = widget.citiesByCountry.value[iso2] ?? const <String>[];
    final nextCities = current.where((c) => c != city).toList()..sort();

    final next = Map<String, List<String>>.from(widget.citiesByCountry.value);
    next[iso2] = nextCities;
    widget.citiesByCountry.value = next;
  }

  Future<void> _removeCountryWithConfirm(BuildContext context, String iso2) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove country?'),
        content: const Text(
            'Removing this country will also remove all its selected cities.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
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
        title: const Text('Remove country?'),
        content: const Text(
          'A country must have at least one city. If you continue, the country will be removed from your map.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeCountry(String iso2) {
    final nextSel = Set<String>.from(widget.selectedIds.value)..remove(iso2);
    widget.selectedIds.value = nextSel;

    final nextCities =
    Map<String, List<String>>.from(widget.citiesByCountry.value);
    nextCities.remove(iso2);
    widget.citiesByCountry.value = nextCities;

    setState(() => _expanded.remove(iso2));
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
