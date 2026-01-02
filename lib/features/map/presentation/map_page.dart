import 'package:flutter/material.dart';

import '../../../shared/map/world_map_models.dart';
import '../../countries/presentation/countries_page.dart';
import '../widgets/world_map_view.dart';
import 'widgets/country_picker_sheet.dart';

class MapPage extends StatelessWidget {
  final WorldMapData worldMap;
  final ValueNotifier<Set<String>> selectedIds;

  final ValueNotifier<Map<String, List<String>>> citiesByCountry;
  final Map<String, List<String>> iso2ToCities;

  const MapPage({
    super.key,
    required this.worldMap,
    required this.selectedIds,
    required this.citiesByCountry,
    required this.iso2ToCities,
  });

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
                title: const Text('Add country'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCountryPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('Add city'),
                subtitle:
                const Text('Manage cities in already added countries'),
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
          worldMap: worldMap,
          selectedIds: selectedIds,
          citiesByCountry: citiesByCountry,
          iso2ToCities: iso2ToCities,
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
          selectedIds: selectedIds,
          citiesByCountry: citiesByCountry,
          countryNameById: worldMap.nameById,
          iso2ToCities: iso2ToCities,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorldMapView(
        map: worldMap,
        selectedIds: selectedIds,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
