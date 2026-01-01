import 'package:flutter/material.dart';
import '../data/svg_map_repository.dart';
import '../domain/country_info.dart';
import '../../../shared/utils/flag_emoji.dart';
import '../domain/map_region.dart';
import 'widgets/bounded_interactive_map.dart';
import 'widgets/map_camera_controller.dart';
import 'widgets/svg_world_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _cameraController = MapCameraController();
  final ValueNotifier<double> _scale = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> _isInteracting = ValueNotifier<bool>(false);

  // Selected countries by ISO2 id (matches SVG id="AF", "DE", ...)
  final ValueNotifier<Set<String>> _selectedIds = ValueNotifier<Set<String>>(<String>{});

  static const _svgPath = 'assets/maps/world.svg';

  final SvgMapRepository _repo = SvgMapRepository();
  late final Future<List<CountryInfo>> _countriesFuture = _repo.extractCountries(_svgPath);

  @override
  void initState() {
    super.initState();

    // Focus Africa once after first frame (map is mounted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraController.focusOnRegion(MapRegion.africa);
    });
  }

  @override
  void dispose() {
    _scale.dispose();
    _isInteracting.dispose();
    _selectedIds.dispose();
    super.dispose();
  }

  void _openAddMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Country'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCountryPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('City'),
                subtitle: const Text('Coming later'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('City: later')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return FutureBuilder<List<CountryInfo>>(
          future: _countriesFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: Text('Failed:\n${snap.error}')),
              );
            }

            return _CountryPickerSheet(
              allCountries: snap.data ?? const [],
              selectedIds: _selectedIds,
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMenu,
        child: const Icon(Icons.add),
      ),
      body: SizedBox.expand(
        child: BoundedInteractiveMap(
          controller: _cameraController,
          scaleNotifier: _scale,
          isInteractingNotifier: _isInteracting,
          child: SvgWorldMap(
            assetPath: _svgPath,
            scaleListenable: _scale,
            isInteracting: _isInteracting,
            selectedIds: _selectedIds,
            baseBorderWidth: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<CountryInfo> allCountries;
  final ValueNotifier<Set<String>> selectedIds;

  const _CountryPickerSheet({
    required this.allCountries,
    required this.selectedIds,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    final filtered = widget.allCountries.where((c) {
      if (_q.isEmpty) return true;
      return c.name.toLowerCase().contains(_q);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search countries…',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: widget.selectedIds,
                  builder: (context, selected, _) {
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        final id = c.id.toUpperCase();
                        final checked = selected.contains(id);

                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) {
                            final next = {...selected};
                            if (v == true) {
                              next.add(id);
                            } else {
                              next.remove(id);
                            }
                            widget.selectedIds.value = next; // triggers map recolor
                          },
                          title: Text(c.name),
                          secondary: Text(
                            flagEmojiFromIso2(id),
                            style: const TextStyle(fontSize: 22),
                          ),
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
      ),
    );
  }
}
