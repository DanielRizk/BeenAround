import 'package:flutter/material.dart';

class CityPickerSheet extends StatefulWidget {
  final String iso2;
  final String countryName;
  final String flag;
  final List<String> allCities;
  final List<String> initiallySelected;

  const CityPickerSheet({
    super.key,
    required this.iso2,
    required this.countryName,
    required this.flag,
    required this.allCities,
    required this.initiallySelected,
  });

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected.toSet();
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
        ? widget.allCities
        : widget.allCities.where((c) => c.toLowerCase().contains(_q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            ListTile(
              leading: Text(widget.flag, style: const TextStyle(fontSize: 22)),
              title: Text(widget.countryName),
              subtitle: Text(widget.iso2),
              trailing: TextButton(
                onPressed: () {
                  final out = _selected.toList()..sort();
                  Navigator.pop(context, out);
                },
                child: const Text('Done'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search city',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              // child: Row(
              //   children: [
              //     Text('Selected: ${_selected.length}'),
              //     const Spacer(),
              //     TextButton(
              //       onPressed: _selected.isEmpty ? null : () => setState(() => _selected.clear()),
              //       child: const Text('Clear'),
              //     ),
              //   ],
              // ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final city = filtered[i];
                  final checked = _selected.contains(city);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (_) {
                      setState(() {
                        if (checked) {
                          _selected.remove(city);
                        } else {
                          _selected.add(city);
                        }
                      });
                    },
                    title: Text(city),
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
