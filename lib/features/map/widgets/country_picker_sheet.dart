import 'package:flutter/material.dart';
import '../../../core/country.dart';

class CountryPickerSheet extends StatefulWidget {
  final List<Country> countries;
  final Set<String> visitedIso2;
  final ValueChanged<Set<String>> onChanged;

  const CountryPickerSheet({
    super.key,
    required this.countries,
    required this.visitedIso2,
    required this.onChanged,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _query = '';
  late final Set<String> _local = {...widget.visitedIso2};

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.countries
        : widget.countries.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.iso2.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8, // 👈 fixed height
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select visited countries',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onChanged(Set<String>.from(_local));
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Search
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search country',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),

              // List (fills remaining space, never shrinks)
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final checked = _local.contains(c.iso2);

                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v ?? false) {
                            _local.add(c.iso2);
                          } else {
                            _local.remove(c.iso2);
                          }
                        });
                        widget.onChanged(Set<String>.from(_local));
                      },
                      secondary: Text(_flag(c.iso2),
                          style: const TextStyle(fontSize: 24)),
                      title: Text(c.name),
                      subtitle: Text(c.iso2),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _flag(String iso2) {
    final s = iso2.toUpperCase();
    final first = s.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = s.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }
}
