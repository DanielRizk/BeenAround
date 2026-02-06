import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SelectedCountryColorMode {
  single,
  multicolor,
}

/// App-wide settings persisted via SharedPreferences.
class AppSettingsController extends ChangeNotifier {
  /// Bump this whenever you change snapshot structure.
  static const int snapshotSchemaVersion = 1;

  static const _kThemeMode = 'themeMode';
  static const _kSeedColor = 'colorSchemeSeed';
  static const _kSelectedCountryColor = 'selectedCountryColor';
  static const _kSelectedCountryColorMode = 'selectedCountryColorMode';
  static const _kShowLabels = 'showCountryLabels';
  static const _kLocale = 'locale';

  static const _kPrivacyNotifications = 'privacyNotifications';
  static const _kPrivacyLocation = 'privacyLocation';
  static const _kPrivacyCountryDetection = 'privacyCountryDetection';
  static const _kDevModeEnabled = 'devModeEnabled';

  bool _privacyNotifications = false;
  bool _privacyLocation = false;
  bool _privacyCountryDetection = false;
  bool _devModeEnabled = false;

  bool get privacyNotifications => _privacyNotifications;
  bool get privacyLocation => _privacyLocation;
  bool get privacyCountryDetection => _privacyCountryDetection;
  bool get devModeEnabled => _devModeEnabled;

  /// The palette used when multicolor is enabled.
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

  /// Call once before runApp()
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    _themeMode =
    ThemeMode.values[sp.getInt(_kThemeMode) ?? ThemeMode.system.index];
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

    _privacyNotifications = sp.getBool(_kPrivacyNotifications) ?? false;
    _privacyLocation = sp.getBool(_kPrivacyLocation) ?? false;
    _privacyCountryDetection = sp.getBool(_kPrivacyCountryDetection) ?? false;
    _devModeEnabled = sp.getBool(_kDevModeEnabled) ?? false;

    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kThemeMode, _themeMode.index);
    await sp.setInt(_kSeedColor, _colorSchemeSeed.toARGB32());
    await sp.setInt(_kSelectedCountryColor, _selectedCountryColor.toARGB32());
    await sp.setInt(_kSelectedCountryColorMode, _selectedCountryColorMode.index);
    await sp.setBool(_kShowLabels, _showCountryLabels);
    await sp.setString(_kLocale, _locale.languageCode);

    await sp.setBool(_kPrivacyNotifications, _privacyNotifications);
    await sp.setBool(_kPrivacyLocation, _privacyLocation);
    await sp.setBool(_kPrivacyCountryDetection, _privacyCountryDetection);
    await sp.setBool(_kDevModeEnabled, _devModeEnabled);
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
    // picking a concrete color switches to single
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

  void setPrivacyNotifications(bool v) {
    if (_privacyNotifications == v) return;
    _privacyNotifications = v;
    _save();
    notifyListeners();
  }

  void setPrivacyLocation(bool v) {
    if (_privacyLocation == v) return;
    _privacyLocation = v;
    _save();
    notifyListeners();
  }

  void setPrivacyCountryDetection(bool v) {
    if (_privacyCountryDetection == v) return;
    _privacyCountryDetection = v;
    _save();
    notifyListeners();
  }

  void setDevModeEnabled(bool v) {
    if (_devModeEnabled == v) return;
    _devModeEnabled = v;
    _save();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kThemeMode);
    await sp.remove(_kSeedColor);
    await sp.remove(_kSelectedCountryColor);
    await sp.remove(_kSelectedCountryColorMode);
    await sp.remove(_kShowLabels);
    await sp.remove(_kLocale);
    await sp.remove(_kPrivacyNotifications);
    await sp.remove(_kPrivacyLocation);
    await sp.remove(_kPrivacyCountryDetection);
    await sp.remove(_kDevModeEnabled);

    _themeMode = ThemeMode.system;
    _colorSchemeSeed = Colors.blue;
    _selectedCountryColor = Colors.orange;
    _selectedCountryColorMode = SelectedCountryColorMode.single;
    _showCountryLabels = true;
    _locale = const Locale('en');
    _privacyNotifications = false;
    _privacyLocation = false;
    _privacyCountryDetection = false;
    _devModeEnabled = false;

    notifyListeners();
  }

  // ==========================================================
  // ✅ New: snapshot export/import for server backup/hydration
  // ==========================================================

  Map<String, dynamic> exportToJson() {
    return {
      'themeMode': _themeMode.index,
      'colorSchemeSeed': _colorSchemeSeed.toARGB32(),
      'selectedCountryColor': _selectedCountryColor.toARGB32(),
      'selectedCountryColorMode': _selectedCountryColorMode.index,
      'showCountryLabels': _showCountryLabels,
      'locale': _locale.languageCode,
      'privacyNotifications': _privacyNotifications,
      'privacyLocation': _privacyLocation,
      'privacyCountryDetection': _privacyCountryDetection,
      'devModeEnabled': _devModeEnabled,
    };
  }

  Future<void> importFromJson(Map<String, dynamic> json) async {
    // Apply but stay defensive for missing fields
    final tm = json['themeMode'];
    if (tm != null) {
      final idx = tm is int ? tm : int.tryParse(tm.toString());
      if (idx != null && idx >= 0 && idx < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[idx];
      }
    }

    final seed = json['colorSchemeSeed'];
    if (seed != null) {
      final v = seed is int ? seed : int.tryParse(seed.toString());
      if (v != null) _colorSchemeSeed = Color(v);
    }

    final sel = json['selectedCountryColor'];
    if (sel != null) {
      final v = sel is int ? sel : int.tryParse(sel.toString());
      if (v != null) _selectedCountryColor = Color(v);
    }

    final mode = json['selectedCountryColorMode'];
    if (mode != null) {
      final idx = mode is int ? mode : int.tryParse(mode.toString());
      if (idx != null &&
          idx >= 0 &&
          idx < SelectedCountryColorMode.values.length) {
        _selectedCountryColorMode = SelectedCountryColorMode.values[idx];
      }
    }

    final labels = json['showCountryLabels'];
    if (labels is bool) _showCountryLabels = labels;

    final lang = json['locale']?.toString();
    if (lang != null && lang.isNotEmpty) _locale = Locale(lang);

    final pn = json['privacyNotifications'];
    if (pn is bool) _privacyNotifications = pn;

    final pl = json['privacyLocation'];
    if (pl is bool) _privacyLocation = pl;

    final pcd = json['privacyCountryDetection'];
    if (pcd is bool) _privacyCountryDetection = pcd;

    final dev = json['devModeEnabled'];
    if (dev is bool) _devModeEnabled = dev;

    // persist + notify
    await _save();
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
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context');
    return scope!.notifier!;
  }
}

/// Your code already uses toARGB32(), so keep it here if you don’t have it elsewhere.
extension _ColorArgb32 on Color {
  int toARGB32() => value;
}
