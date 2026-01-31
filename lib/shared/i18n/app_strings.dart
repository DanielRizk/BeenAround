import 'package:flutter/widgets.dart';

enum AppLang { en, de }

class S {
  static AppLang lang(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'de' ? AppLang.de : AppLang.en;
  }

  static String t(BuildContext context, String key) {
    final l = lang(context);
    return _map[l]![key] ?? key;
  }

  static const Map<AppLang, Map<String, String>> _map = {
    AppLang.en: {
      //===========================================
      //              Bottom nav
      //===========================================
      'tab_map': 'Map',
      'tab_countries': 'Countries',
      'tab_stats': 'Stats',
      'tab_friends': 'Friends',
      'tab_settings': 'Settings',

      //===========================================
      //              Map Page
      //===========================================
      'add_country': 'Add country',
      'search_country': 'Search country',
      'remove_country': 'Remove country?',
      'remove_country_confirm': 'By unchecking this country all cities saved will be lost.',
      'add_city': 'Add city',
      'add_city_subtitle': 'Manage cities in current countries',
      'search_city': 'Search city',
      'minimum_one_city': 'You need to choose a minimum of one city to add the country.',
      'no_available_cities': 'No cities available for this country',

      //===========================================
      //          Map Country Details Overlay
      //===========================================
      'country_details': 'Country details',
      'visited_on': 'Visited on',
      'notes': 'Notes',
      'add_note': 'Add a note',
      'edit_date': 'Edit date',
      'back': 'Back',

      //===========================================
      //              Countries Page
      //===========================================
      'country': 'Country',
      'city': 'City',
      'cities': 'Cities',
      'visited': 'Visited',
      'manage_cities': 'Manage cities',
      'edit_cities': 'Edit cities',
      'no_cities_selected': 'No cities selected yet.',
      'no_countries_selected': 'No countries selected yet.',
      'country_needs_at_least_one_city': 'A country needs at least one city. If you uncheck this city the country will be removed.',
      'cities_will_be_lost_remove_country_confirm': 'Removing this country will also remove all its selected cities.',

      //===========================================
      //              Stats Page
      //===========================================
      'worldwide': 'Worldwide',
      'continents': 'Continents',
      'country_visited': 'Country Visited',
      'country_not_visited': 'Country not yet Visited',

      //===========================================
      //              Settings Page
      //===========================================

      // Settings root
      'settings_title': 'Settings',
      'settings_account': 'Account',
      'settings_account_sub': 'Placeholder for now',
      'settings_appearance': 'Appearance',
      'settings_appearance_sub': 'Theme, colors, map labels',
      'settings_language': 'Language',
      'reset_app_data': 'Reset app data',
      'reset_app_data_subtitle': 'Clears countries, and cities, friends and saved settings',
      'reset_everything': 'Reset everything?',
      'reset_everything_confirm': 'This will clear ALL locally saved data and return the app to defaults.',
      'reset_confirmation': 'App data cleared.',



      // Appearance section
      'theme_mode': 'Theme mode',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'color_scheme': 'Color scheme',
      'app_color': 'App color',
      'app_color_scheme': 'App color scheme',
      'map_section': 'Map',
      'show_country_labels': 'Show country labels',
      'selected_country_color': 'Selected countries color',

      // Language section
      'lang_en': 'English',
      'lang_de': 'Deutsch',

      //===========================================
      //              System
      //===========================================

      // Operations
      'confirm': 'Confirm',
      'keep': 'Keep',
      'remove': 'Remove',
      'cancel': 'Cancel',
      'close': 'Close',
      'done': 'Done',
      'reset': 'Reset',

      // Colors
      'blue': 'Blue',
      'teal': 'Teal',
      'green': 'Green',
      'amber': 'Amber',
      'orange': 'Orange',
      'pink': 'Pink',
      'purple': 'Purple',
      'red': 'Red',
      'multicolor': 'Multicolor',

    },
    AppLang.de: {
      //===========================================
      //              Bottom nav
      //===========================================
      'tab_map': 'Karte',
      'tab_countries': 'Länder',
      'tab_stats': 'Statistik',
      'tab_friends': 'Freunde',
      'tab_settings': 'Einst.',

      //===========================================
      //              Map Page
      //===========================================
      'add_country': 'Land hinzufügen',
      'search_country': 'Land suchen',
      'remove_country': 'Land entfernen?',
      'remove_country_confirm': 'Wenn Sie dieses Land deaktivieren, gehen alle gespeicherten Städte verloren.',
      'add_city': 'Stadt hinzufügen',
      'add_city_subtitle': 'Städte in den aktuellen Ländern verwalten',
      'search_city': 'Stadt suchen',
      'minimum_one_city': 'Sie müssen mindestens eine Stadt auswählen, um das Land hinzuzufügen.',
      'no_available_cities': 'Keine Städte für dieses Land verfügbar',

      //===========================================
      //          Map Country Details Overlay
      //===========================================
      'country_details': 'Land-Details',
      'visited_on': 'Besucht am',
      'notes': 'Notizen',
      'add_note': 'Notiz hinzufügen',
      'edit_date': 'Datum ändern',
      'back': 'Zurück',

      //===========================================
      //              Countries Page
      //===========================================
      'country': 'Land',
      'city': 'Stadt',
      'cities': 'Städte',
      'visited': 'Besucht',
      'manage_cities': 'Städte verwalten',
      'edit_cities': 'Städte bearbeiten',
      'no_cities_selected': 'Noch keine Städte ausgewählt.',
      'no_countries_selected': 'Noch keine Länder ausgewählt.',
      'country_needs_at_least_one_city': 'Ein Land benötigt mindestens eine Stadt. Wenn Sie diese Stadt deaktivieren, wird das Land entfernt.',
      'cities_will_be_lost_remove_country_confirm': 'Wenn Sie dieses Land entfernen, werden auch alle ausgewählten Städte entfernt.',

      //===========================================
      //              Stats Page
      //===========================================
      'worldwide': 'Weltweit',
      'continents': 'Kontinente',
      'country_visited': 'Land Besucht',
      'country_not_visited': 'Land noch nicht Besucht',

      //===========================================
      //              Settings Page
      //===========================================

      // Settings root
      'settings_title': 'Einstellungen',
      'settings_account': 'Konto',
      'settings_account_sub': 'Platzhalter fürs Erste',
      'settings_appearance': 'Darstellung',
      'settings_appearance_sub': 'Theme, Farben, Kartenbeschriftung',
      'settings_language': 'Sprache',
      'reset_app_data': 'Appdaten zurücksetzen',
      'reset_app_data_subtitle': 'Löscht Länder, Städte, Freunde und gespeicherte Einstellungen',
      'reset_everything': 'Alles zurücksetzen?',
      'reset_everything_confirm': 'Dadurch werden ALLE lokal gespeicherten Daten gelöscht und die App auf die Standardeinstellungen zurückgesetzt.',
      'reset_confirmation': 'App-Daten gelöscht.',

      // Appearance section
      'theme_mode': 'Designmodus',
      'theme_system': 'System',
      'theme_light': 'Hell',
      'theme_dark': 'Dunkel',
      'color_scheme': 'Farbschema',
      'app_color': 'App-Farbe',
      'app_color_scheme': 'App-Farbschema',
      'map_section': 'Karte',
      'show_country_labels': 'Länderbeschriftung anzeigen',
      'selected_country_color': 'Farbe ausgewählter Länder',

      // Language section
      'lang_en': 'English',
      'lang_de': 'Deutsch',

      //===========================================
      //              System
      //===========================================

      // Operations
      'confirm': 'Bestätigen',
      'keep': 'Behalten',
      'remove': 'Entfernen',
      'cancel': 'Abbrechen',
      'close': 'Schließen',
      'done': 'Fertig',
      'reset': 'Zurücksetzen',

      // Colors
      'blue': 'Blau',
      'teal': 'Türkis',
      'green': 'Grün',
      'amber': 'Bernstein',
      'orange': 'Orange',
      'pink': 'Rosa',
      'purple': 'Lila',
      'red': 'Rot',
      'multicolor': 'Mehrfarbig',
    },
  };
}
