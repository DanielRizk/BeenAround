import 'package:flutter/material.dart';
import '../../../../shared/map/world_map_models.dart';
import 'city_picker_sheet.dart';

class CountryPickerSheet extends StatefulWidget {
  final WorldMapData worldMap;
  final ValueNotifier<Set<String>> selectedIds;

  // ✅ new
  final ValueNotifier<Map<String, List<String>>> citiesByCountry;
  final Map<String, List<String>> iso2ToCities;

  const CountryPickerSheet({
    super.key,
    required this.worldMap,
    required this.selectedIds,
    required this.citiesByCountry,
    required this.iso2ToCities,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';
  late final List<_CountryRow> _all;

  @override
  void initState() {
    super.initState();

    final shapeIds = widget.worldMap.countries.map((c) => c.id).toSet();
    _all = widget.worldMap.nameById.entries
        .where((e) => shapeIds.contains(e.key))
        .map((e) => _CountryRow(id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _search.addListener(() => setState(() => _q = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? _all
        : _all.where((c) {
      final n = c.name.toLowerCase();
      final id = c.id.toLowerCase();
      return n.contains(_q) || id.contains(_q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search country (name or ISO2)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // summary + clear
            ValueListenableBuilder<Set<String>>(
              valueListenable: widget.selectedIds,
              builder: (context, ids, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  // child: Row(
                  //   children: [
                  //     Text('Selected: ${ids.length}'),
                  //     const Spacer(),
                  //     TextButton(
                  //       onPressed: ids.isEmpty ? null : _clearAll,
                  //       child: const Text('Clear'),
                  //     ),
                  //   ],
                  // ),
                );
              },
            ),

            const Divider(height: 1),

            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: widget.selectedIds,
                builder: (context, ids, _) {
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final isSelected = ids.contains(c.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _onToggleCountry(context, c, isSelected),
                        secondary: Text(
                          _flagEmojiFromIso2(c.id),
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(c.name),
                        subtitle: Text(c.id),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggleCountry(BuildContext context, _CountryRow c, bool isSelected) async {
    if (!isSelected) {
      // ✅ selecting country -> must pick >= 1 city, then Done
      final allCities = widget.iso2ToCities[c.id] ?? const <String>[];
      if (allCities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cities available for this country.')),
        );
        return;
      }

      final picked = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => CityPickerSheet(
          iso2: c.id,
          countryName: c.name,
          flag: _flagEmojiFromIso2(c.id),
          allCities: allCities,
          initiallySelected: const [],
        ),
      );

      if (picked == null) return; // cancelled

      if (picked.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to choose a minimum of one city to add the country.'),
          ),
        );
        return;
      }

      // ✅ commit country + cities
      final nextCities = Map<String, List<String>>.from(widget.citiesByCountry.value);
      nextCities[c.id] = picked;
      widget.citiesByCountry.value = nextCities;

      final nextSel = Set<String>.from(widget.selectedIds.value)..add(c.id);
      widget.selectedIds.value = nextSel;

      return;
    }

    // ✅ unselecting country -> confirm destructive
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove country?'),
        content: const Text('By unchecking this country all cities saved will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (ok != true) return;

    final nextSel = Set<String>.from(widget.selectedIds.value)..remove(c.id);
    widget.selectedIds.value = nextSel;

    final nextCities = Map<String, List<String>>.from(widget.citiesByCountry.value);
    nextCities.remove(c.id);
    widget.citiesByCountry.value = nextCities;
  }

  void _clearAll() {
    widget.selectedIds.value = <String>{};
    widget.citiesByCountry.value = <String, List<String>>{};
  }
}

class _CountryRow {
  final String id;
  final String name;
  const _CountryRow({required this.id, required this.name});
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
