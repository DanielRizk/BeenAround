import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SelectedCountryColorMode {
  single,
  multicolor,
}

/// App-wide settings (kept intentionally simple: no persistence yet).
/// You can later persist these with SharedPreferences/Hive.
class AppSettingsController extends ChangeNotifier {
  static const _kThemeMode = 'themeMode';
  static const _kSeedColor = 'colorSchemeSeed';
  static const _kSelectedCountryColor = 'selectedCountryColor';
  static const _kSelectedCountryColorMode = 'selectedCountryColorMode';
  static const _kShowLabels = 'showCountryLabels';
  static const _kLocale = 'locale';

  /// The palette used when the "multicolor" option is enabled.
  /// Keep this in one place so UI + painter stay in sync.
  static const List<Color> countryColorPalette = <Color>[
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.red,
  ];

  ThemeMode _themeMode = ThemeMode.system;
  Color _colorSchemeSeed = Colors.blue;
  Color _selectedCountryColor = Colors.orange;
  SelectedCountryColorMode _selectedCountryColorMode =
      SelectedCountryColorMode.single;
  bool _showCountryLabels = true;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Color get colorSchemeSeed => _colorSchemeSeed;
  Color get selectedCountryColor => _selectedCountryColor;
  SelectedCountryColorMode get selectedCountryColorMode =>
      _selectedCountryColorMode;
  bool get showCountryLabels => _showCountryLabels;
  Locale get locale => _locale;

  /// Call this ONCE before runApp()
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    _themeMode = ThemeMode.values[
    sp.getInt(_kThemeMode) ?? ThemeMode.system.index];
    _colorSchemeSeed =
        Color(sp.getInt(_kSeedColor) ?? Colors.blue.toARGB32());
    _selectedCountryColor = Color(
        sp.getInt(_kSelectedCountryColor) ?? Colors.orange.toARGB32());
    _selectedCountryColorMode = SelectedCountryColorMode.values[
    sp.getInt(_kSelectedCountryColorMode) ??
        SelectedCountryColorMode.single.index];
    _showCountryLabels = sp.getBool(_kShowLabels) ?? true;

    final lang = sp.getString(_kLocale);
    if (lang != null) {
      _locale = Locale(lang);
    }

    notifyListeners();
  }

  void _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kThemeMode, _themeMode.index);
    await sp.setInt(_kSeedColor, _colorSchemeSeed.toARGB32());
    await sp.setInt(_kSelectedCountryColor, _selectedCountryColor.toARGB32());
    await sp.setInt(
        _kSelectedCountryColorMode, _selectedCountryColorMode.index);
    await sp.setBool(_kShowLabels, _showCountryLabels);
    await sp.setString(_kLocale, _locale.languageCode);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _save();
    notifyListeners();
  }

  void setColorSchemeSeed(Color color) {
    if (_colorSchemeSeed.toARGB32() == color.toARGB32()) return;
    _colorSchemeSeed = color;
    _save();
    notifyListeners();
  }

  void setSelectedCountryColor(Color color) {
    if (_selectedCountryColor.toARGB32() == color.toARGB32()) return;
    _selectedCountryColor = color;
    // If user picks a concrete color, we switch back to "single".
    _selectedCountryColorMode = SelectedCountryColorMode.single;
    _save();
    notifyListeners();
  }

  void setSelectedCountryColorMode(SelectedCountryColorMode mode) {
    if (_selectedCountryColorMode == mode) return;
    _selectedCountryColorMode = mode;
    _save();
    notifyListeners();
  }

  void setShowCountryLabels(bool v) {
    if (_showCountryLabels == v) return;
    _showCountryLabels = v;
    _save();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    _save();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('themeMode');
    await sp.remove('colorSchemeSeed');
    await sp.remove('selectedCountryColor');
    await sp.remove('selectedCountryColorMode');
    await sp.remove('showCountryLabels');
    await sp.remove('locale');

    // defaults
    _themeMode = ThemeMode.system;
    _colorSchemeSeed = Colors.blue;
    _selectedCountryColor = Colors.orange;
    _selectedCountryColorMode = SelectedCountryColorMode.single;
    _showCountryLabels = true;
    _locale = const Locale('en');

    notifyListeners();
  }
}

/// Access anywhere via: `final settings = AppSettingsScope.of(context);`
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AppSettingsController of(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context');
    return scope!.notifier!;
  }
}
