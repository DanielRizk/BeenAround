import 'package:flutter/material.dart';
import '../../../../shared/settings/app_settings.dart';
import '../../../shared/i18n/app_strings.dart';

import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_dialogs.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_tiles.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const List<Color> _palette = AppSettingsController.countryColorPalette;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AppScaffold(
      title: S.t(context, 'settings_appearance'),
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final themeMode = settings.themeMode;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SectionCard(
                title: S.t(context, 'theme_mode'),
                child: Column(
                  children: [
                    SelectMotionTile(
                      icon: Icons.auto_awesome_rounded,
                      title: S.t(context, 'theme_system'),
                      subtitle: S.t(context, 'theme_system'),
                      selected: themeMode == ThemeMode.system,
                      onTap: () => settings.setThemeMode(ThemeMode.system),
                    ),
                    const SoftDivider(),
                    SelectMotionTile(
                      icon: Icons.light_mode_rounded,
                      title: S.t(context, 'theme_light'),
                      subtitle: S.t(context, 'theme_light'),
                      selected: themeMode == ThemeMode.light,
                      onTap: () => settings.setThemeMode(ThemeMode.light),
                    ),
                    const SoftDivider(),
                    SelectMotionTile(
                      icon: Icons.dark_mode_rounded,
                      title: S.t(context, 'theme_dark'),
                      subtitle: S.t(context, 'theme_dark'),
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => settings.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SectionCard(
                title: S.t(context, 'color_scheme'),
                child: Column(
                  children: [
                    MotionTile(
                      icon: Icons.palette_outlined,
                      title: S.t(context, 'app_color'),
                      subtitle: _colorName(context, settings.colorSchemeSeed),
                      onTap: () async {
                        final picked = await AppDialogs.showColorPalettePicker(
                          context: context,
                          title: S.t(context, 'app_color_scheme'),
                          palette: _palette,
                          current: settings.colorSchemeSeed,
                          cancelLabel: S.t(context, 'cancel'),
                        );
                        if (picked != null) settings.setColorSchemeSeed(picked);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SectionCard(
                title: S.t(context, 'map_section'),
                child: Column(
                  children: [
                    SwitchMotionTile(
                      icon: Icons.text_fields_outlined,
                      title: S.t(context, 'show_country_labels'),
                      subtitle: S.t(context, 'show_country_labels'),
                      value: settings.showCountryLabels,
                      onChanged: settings.setShowCountryLabels,
                    ),
                    const SoftDivider(),
                    MotionTile(
                      icon: Icons.public,
                      title: S.t(context, 'selected_country_color'),
                      subtitle: settings.selectedCountryColorMode == SelectedCountryColorMode.multicolor
                          ? S.t(context, 'multicolor')
                          : _colorName(context, settings.selectedCountryColor),
                      onTap: () async {
                        final picked = await AppDialogs.showSelectedCountryColorPicker(
                          context: context,
                          title: S.t(context, 'selected_country_color'),
                          palette: _palette,
                          mode: settings.selectedCountryColorMode,
                          currentColor: settings.selectedCountryColor,
                          cancelLabel: S.t(context, 'cancel'),
                        );

                        if (picked == null) return;

                        if (picked.mode == SelectedCountryColorMode.multicolor) {
                          settings.setSelectedCountryColorMode(SelectedCountryColorMode.multicolor);
                        } else if (picked.color != null) {
                          settings.setSelectedCountryColor(picked.color!);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _colorName(BuildContext context, Color c) {
    final v = c.toARGB32();

    if (v == Colors.blue.toARGB32()) return S.t(context, 'blue');
    if (v == Colors.teal.toARGB32()) return S.t(context, 'teal');
    if (v == Colors.green.toARGB32()) return S.t(context, 'green');
    if (v == Colors.amber.toARGB32()) return S.t(context, 'amber');
    if (v == Colors.orange.toARGB32()) return S.t(context, 'orange');
    if (v == Colors.pink.toARGB32()) return S.t(context, 'pink');
    if (v == Colors.purple.toARGB32()) return S.t(context, 'purple');
    if (v == Colors.red.toARGB32()) return S.t(context, 'red');

    return '#${v.toRadixString(16).padLeft(8, '0')}';
  }
}