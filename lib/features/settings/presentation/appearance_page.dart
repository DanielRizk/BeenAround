import 'package:flutter/material.dart';
import '../../../../shared/settings/app_settings.dart';
import '../../../shared/i18n/app_strings.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const List<Color> _palette = AppSettingsController.countryColorPalette;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_appearance'))),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _sectionTitle(context, S.t(context, 'theme_mode')),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                title: Text(S.t(context, 'theme_system')),
                onChanged: (v) => settings.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                title: Text(S.t(context, 'theme_light')),
                onChanged: (v) => settings.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                title: Text(S.t(context, 'theme_dark')),
                onChanged: (v) => settings.setThemeMode(v!),
              ),

              const Divider(height: 24),

              _sectionTitle(context, S.t(context, 'color_scheme')),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(S.t(context, 'app_color')),
                subtitle: Text(_colorName(context, settings.colorSchemeSeed)),
                trailing: _colorDot(settings.colorSchemeSeed),
                onTap: () => _pickColor(
                  context,
                  title: S.t(context, 'app_color_scheme'),
                  current: settings.colorSchemeSeed,
                  onPick: settings.setColorSchemeSeed,
                ),
              ),

              const Divider(height: 24),

              _sectionTitle(context, S.t(context, 'map_section')),
              SwitchListTile(
                secondary: const Icon(Icons.text_fields_outlined),
                title: Text(S.t(context, 'show_country_labels')),
                value: settings.showCountryLabels,
                onChanged: settings.setShowCountryLabels,
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(S.t(context, 'selected_country_color')),
                subtitle: Text(
                  settings.selectedCountryColorMode ==
                      SelectedCountryColorMode.multicolor
                      ? S.t(context, 'multicolor')
                      : _colorName(context, settings.selectedCountryColor),
                ),
                trailing: settings.selectedCountryColorMode ==
                    SelectedCountryColorMode.multicolor
                    ? _multiColorDot(_palette)
                    : _colorDot(settings.selectedCountryColor),
                onTap: () => _pickSelectedCountryColor(context, settings),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _colorDot(Color c) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
    );
  }

  Widget _multiColorDot(List<Color> palette) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
        gradient: SweepGradient(colors: palette),
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

  Future<void> _pickColor(
      BuildContext context, {
        required String title,
        required Color current,
        required void Function(Color) onPick,
      }) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _palette)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.pop(ctx, c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: (c.value == current.value) ? 3 : 1,
                        color: (c.value == current.value)
                            ? Theme.of(ctx).colorScheme.onSurface
                            : Colors.black26,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.t(context, 'cancel')),
            ),
          ],
        );
      },
    );

    if (picked != null) onPick(picked);
  }

  Future<void> _pickSelectedCountryColor(
      BuildContext context,
      AppSettingsController settings,
      ) async {
    final picked = await showDialog<_SelectedColorPick>(
      context: context,
      builder: (ctx) {
        final currentMode = settings.selectedCountryColorMode;
        final currentColor = settings.selectedCountryColor;

        return AlertDialog(
          title: Text(S.t(context, 'selected_country_color')),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Multicolor option
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    Navigator.pop(ctx, const _SelectedColorPick.multicolor()),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: _palette),
                    border: Border.all(
                      width:
                      (currentMode == SelectedCountryColorMode.multicolor)
                          ? 3
                          : 1,
                      color:
                      (currentMode == SelectedCountryColorMode.multicolor)
                          ? Theme.of(ctx).colorScheme.onSurface
                          : Colors.black26,
                    ),
                  ),
                ),
              ),

              // Single-color options
              for (final c in _palette)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () =>
                      Navigator.pop(ctx, _SelectedColorPick.single(c)),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: (currentMode ==
                            SelectedCountryColorMode.single &&
                            c.value == currentColor.value)
                            ? 3
                            : 1,
                        color: (currentMode ==
                            SelectedCountryColorMode.single &&
                            c.value == currentColor.value)
                            ? Theme.of(ctx).colorScheme.onSurface
                            : Colors.black26,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.t(context, 'cancel')),
            ),
          ],
        );
      },
    );

    if (picked == null) return;
    if (picked.mode == SelectedCountryColorMode.multicolor) {
      settings.setSelectedCountryColorMode(SelectedCountryColorMode.multicolor);
    } else if (picked.color != null) {
      settings.setSelectedCountryColor(picked.color!);
    }
  }
}

class _SelectedColorPick {
  final SelectedCountryColorMode mode;
  final Color? color;

  const _SelectedColorPick.multicolor()
      : mode = SelectedCountryColorMode.multicolor,
        color = null;

  const _SelectedColorPick.single(this.color)
      : mode = SelectedCountryColorMode.single;
}
