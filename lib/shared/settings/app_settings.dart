import 'package:flutter/material.dart';

/// App-wide settings (kept intentionally simple: no persistence yet).
/// You can later persist these with SharedPreferences/Hive.
class AppSettingsController extends ChangeNotifier {
  ThemeMode _themeMode;
  Color _colorSchemeSeed;
  Color _selectedCountryColor;
  bool _showCountryLabels;
  Locale _locale;

  AppSettingsController({
    ThemeMode themeMode = ThemeMode.system,
    Color colorSchemeSeed = Colors.blue,
    Color selectedCountryColor = Colors.orange,
    bool showCountryLabels = true,
    Locale locale = const Locale('en'),
  })  : _themeMode = themeMode,
        _colorSchemeSeed = colorSchemeSeed,
        _selectedCountryColor = selectedCountryColor,
        _showCountryLabels = showCountryLabels,
        _locale = locale;

  ThemeMode get themeMode => _themeMode;
  Color get colorSchemeSeed => _colorSchemeSeed;
  Color get selectedCountryColor => _selectedCountryColor;
  bool get showCountryLabels => _showCountryLabels;
  Locale get locale => _locale;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setColorSchemeSeed(Color color) {
    if (_colorSchemeSeed.value == color.value) return;
    _colorSchemeSeed = color;
    notifyListeners();
  }

  void setSelectedCountryColor(Color color) {
    if (_selectedCountryColor.value == color.value) return;
    _selectedCountryColor = color;
    notifyListeners();
  }

  void setShowCountryLabels(bool v) {
    if (_showCountryLabels == v) return;
    _showCountryLabels = v;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
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
