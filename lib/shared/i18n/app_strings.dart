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

      'settings_privacy': 'Privacy',
      'settings_privacy_sub': 'Notifications and location',
      'privacy_title': 'Privacy',
      'privacy_notifications': 'Notifications',
      'privacy_notifications_sub': 'Allow travel notifications',
      'privacy_location': 'Location',
      'privacy_location_sub': 'Allow GPS / location access',
      'privacy_detection': 'Country detection',
      'privacy_detection_sub': 'Notify when you enter a new country',
      'privacy_hint': 'Country detection requires both notifications and location.',
      'privacy_location_services_off': 'Location services are OFF. Please enable them.',
      'privacy_location_denied': 'Location permission is not granted.',
      'privacy_notifications_denied': 'Notifications are not enabled for this app.',
      'privacy_detection_enabled': 'Country detection enabled.',

      'export_failed': 'Export failed:',
      'export_travel_data': 'Export travel data',
      'export_travel_data_sub': 'Generate a PDF with visited countries & cities.',
      'export_options': 'Export options',
      'export_option_msg': 'Choose what to include in the PDF:',
      'include_notes': 'Include notes',

      //===========================================
      //              Dev Page
      //===========================================
      'dev_mode_title': 'Developer mode',
      'dev_mode_sub': 'Debug and maintenance tools',
      'dev_mode_enable_title': 'Enable Developer Mode?',
      'dev_mode_enable_msg': 'This page is hidden. Enter the 6-digit PIN to enable it.',
      'dev_mode_pin': 'PIN (6 digits)',
      'dev_mode_pin_wrong': 'Wrong PIN',
      'dev_mode_enabled': 'Developer mode enabled',
      'dev_mode_disabled': 'Developer mode disabled',
      'dev_mode_hide': 'Hide',
      'dev_tools_title': 'Debug tools',
      'dev_export_title': 'Export user data (file)',
      'dev_export_sub': 'Export all settings, countries, cities, dates, notes…',
      'dev_import_title': 'Import user data (file)',
      'dev_import_sub': 'Load export file and replace current local data.',
      'dev_test_notification': 'Test Notification',

      //===========================================
      //              Notifications
      //===========================================
      // 'new_country_detection': 'New Country, Yaaay!!!',
      // 'new_country_you_made_it': 'You made it to',
      // 'new_country_tab_to_add_it': '. Tap to add it.',

      //===========================================
      //              PDF Export
      //===========================================
      // 'no_travel_data_yet': 'No travel data yet.',
      // 'page': 'Page',
      // 'world_map': 'World map',


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
      'enable': 'Enable',
      'export': 'Export',

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

      'settings_privacy': 'Privatsphäre',
      'settings_privacy_sub': 'Benachrichtigungen & Standort',
      'privacy_title': 'Privatsphäre',
      'privacy_notifications': 'Benachrichtigungen',
      'privacy_notifications_sub': 'Reise-Benachrichtigungen erlauben',
      'privacy_location': 'Standort',
      'privacy_location_sub': 'GPS/Standortzugriff erlauben',
      'privacy_detection': 'Länder-Erkennung',
      'privacy_detection_sub': 'Hinweis beim Betreten eines neuen Landes',
      'privacy_hint': 'Länder-Erkennung benötigt Benachrichtigungen und Standort.',
      'privacy_location_services_off': 'Standortdienste sind AUS. Bitte aktivieren.',
      'privacy_location_denied': 'Standort-Berechtigung ist nicht erteilt.',
      'privacy_notifications_denied': 'Benachrichtigungen sind für diese App nicht aktiviert.',
      'privacy_detection_enabled': 'Länder-Erkennung aktiviert.',

      'export_failed': 'Export fehlgeschlagen:',
      'export_travel_data': 'Reisedaten exportieren',
      'export_travel_data_sub': 'PDF mit besuchten Ländern und Städten erstellen.',
      'export_options': 'Exportoptionen',
      'export_option_msg': 'Wählen Sie aus, was im PDF enthalten sein soll:',
      'include_notes': 'Notizen einbeziehen',

      //===========================================
      //              Dev Page
      //===========================================

      'dev_mode_title': 'Entwicklermodus',
      'dev_mode_sub': 'Debug- und Wartungs-Tools',
      'dev_mode_enable_title': 'Entwicklermodus aktivieren?',
      'dev_mode_enable_msg': 'Diese Seite ist versteckt. Bitte 6-stellige PIN eingeben.',
      'dev_mode_pin': 'PIN (6 Ziffern)',
      'dev_mode_pin_wrong': 'Falsche PIN',
      'dev_mode_enabled': 'Entwicklermodus aktiviert',
      'dev_mode_disabled': 'Entwicklermodus deaktiviert',
      'dev_mode_hide': 'Ausblenden',
      'dev_tools_title': 'Debug Tools',
      'dev_export_title': 'Benutzerdaten exportieren (Datei)',
      'dev_export_sub': 'Exportiert Einstellungen, Länder, Städte, Daten, Notizen…',
      'dev_import_title': 'Benutzerdaten importieren (Datei)',
      'dev_import_sub': 'Import-Datei laden und lokale Daten ersetzen.',
      'dev_test_notification': 'Benachrichtigung testen',


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
      'enable': 'Aktivieren',
      'export': 'Export',

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
